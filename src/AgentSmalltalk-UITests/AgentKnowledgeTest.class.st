"
Headless tests for phase 4: live fact lookup, the AgentUnknown null-object,
and change announcements (facts and widgets) with auto-unsubscribe.
"
Class {
	#name : 'AgentKnowledgeTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentKnowledgeTest >> setUp [
	super setUp.
	AgentCanvas reset
]

{ #category : 'running' }
AgentKnowledgeTest >> tearDown [
	AgentCanvas reset.
	super tearDown
]

{ #category : 'tests' }
AgentKnowledgeTest >> testAtReadsLiveFactBody [
	AgentFact key: #city body: 'Tokyo'.
	self assert: (AgentKnowledge at: #city) equals: 'Tokyo'
]

{ #category : 'tests' }
AgentKnowledgeTest >> testMissingFactIsUnknownWithKey [
	| value |
	value := AgentKnowledge at: #shoeSize.
	self assert: value isUnknown.
	self assert: value key equals: #shoeSize.
	self assert: value asString equals: 'unknown (shoeSize)'
]

{ #category : 'tests' }
AgentKnowledgeTest >> testAtIfAbsent [
	self assert: (AgentKnowledge at: #nope ifAbsent: [ 'fallback' ]) equals: 'fallback'.
	AgentFact key: #yes body: 'here'.
	self assert: (AgentKnowledge at: #yes ifAbsent: [ 'fallback' ]) equals: 'here'
]

{ #category : 'tests' }
AgentKnowledgeTest >> testNumberAt [
	AgentFact key: #budget body: 'monthly budget is 2500'.
	AgentFact key: #mood body: 'pretty good'.
	self assert: (AgentKnowledge numberAt: #budget) equals: 2500.
	self assert: (AgentKnowledge numberAt: #mood) isUnknown.
	self assert: (AgentKnowledge numberAt: #absent) isUnknown
]

{ #category : 'tests' }
AgentKnowledgeTest >> testNumberAtScansTheFirstCompleteNumericToken [
	AgentFact key: #integer body: 'there are 42 widgets'.
	AgentFact key: #negative body: 'outside temperature is -12 degrees'.
	AgentFact key: #decimal body: 'tax rate is 3.14, then 2.71'.
	AgentFact key: #grouped body: 'budget is $1,234.50 this month'.
	AgentFact key: #multiple body: 'between 10 and 20'.
	AgentFact key: #separated body: 'values: 7 / 8'.
	self assert: (AgentKnowledge numberAt: #integer) equals: 42.
	self assert: (AgentKnowledge numberAt: #negative) equals: -12.
	self assert: (AgentKnowledge numberAt: #decimal) equals: 3.14.
	self assert: (AgentKnowledge numberAt: #grouped) equals: 1234.50.
	self assert: (AgentKnowledge numberAt: #multiple) equals: 10.
	self assert: (AgentKnowledge numberAt: #separated) equals: 7
]

{ #category : 'tests' }
AgentKnowledgeTest >> testNumberAtAnswersUnknownForMalformedOrAbsentValues [
	AgentFact key: #dash body: '-'.
	AgentFact key: #punctuation body: '...'.
	AgentFact key: #words body: 'not a numeric fact'.
	self assert: (AgentKnowledge numberAt: #dash) isUnknown.
	self assert: (AgentKnowledge numberAt: #punctuation) isUnknown.
	self assert: (AgentKnowledge numberAt: #words) isUnknown.
	self assert: (AgentKnowledge numberAt: #missing) isUnknown
]

{ #category : 'tests' }
AgentKnowledgeTest >> testEverythingElseIsNotUnknown [
	self deny: 'a string' isUnknown.
	self deny: 42 isUnknown.
	self deny: nil isUnknown.
	self deny: AgentWidget new isUnknown
]

{ #category : 'tests' }
AgentKnowledgeTest >> testAgentUpdatesAnnounceFactChanged [
	| heard |
	heard := OrderedCollection new.
	AgentCanvas current announcer
		when: AgentFactChanged
		do: [ :evt | heard add: evt key ]
		for: self.
	AgentFact key: #city body: 'Tokyo'.
	AgentFact key: #city body: 'Lisbon'.
	self assert: (heard occurrencesOf: #city) >= 2.
	AgentCanvas current announcer unsubscribe: self
]

{ #category : 'tests' }
AgentKnowledgeTest >> testNewFactAnnouncementSeesLiveFact [
	| observations fact observation |
	observations := OrderedCollection new.
	AgentCanvas current announcer
		when: AgentFactChanged
		do: [ :event |
			observations add: {
				event key.
				AgentKnowledge at: #city.
				AgentCanvas current facts includes: event fact } ]
		for: self.
	[
		fact := AgentFact key: #city body: 'Tokyo'.
		self assert: observations size equals: 1.
		observation := observations first.
		self assert: observation first equals: #city.
		self assert: observation second equals: 'Tokyo'.
		self assert: observation third.
		self assert: (AgentCanvas current factWithKey: #city) identicalTo: fact ]
		ensure: [ AgentCanvas current announcer unsubscribe: self ]
]

{ #category : 'tests' }
AgentKnowledgeTest >> testSandboxReadsNewFactImmediatelyInHeadlessMode [
	self assert: (AgentSandbox new evaluate:
		'AgentFact key: #city body: ''Tokyo''. AgentKnowledge at: #city')
		equals: 'RESULT: ''Tokyo'''
]

{ #category : 'tests' }
AgentKnowledgeTest >> testInteractiveFactIsVisibleBeforeAnnouncementAndPulse [
	| canvas space observations result |
	AgentRemote enable.
	canvas := AgentCanvasInteractiveTestProbe new.
	space := AgentCanvasStaleSpaceProbe new.
	canvas space: space.
	AgentCanvas instVarNamed: #current put: canvas.
	observations := OrderedCollection new.
	canvas announcer
		when: AgentFactChanged
		do: [ :event |
			observations add: {
				event fact.
				AgentKnowledge at: #city.
				canvas facts includes: event fact } ]
		for: self.
	[
		result := AgentSandbox new evaluate:
			'AgentFact key: #city body: ''Tokyo''. AgentKnowledge at: #city'.
		self assert: result equals: 'RESULT: ''Tokyo'''.
		self assert: observations size equals: 1.
		self assert: observations first first identicalTo: (canvas factWithKey: #city).
		self assert: observations first second equals: 'Tokyo'.
		self assert: observations first third.
		self assert: space queuedTasks size equals: 1.
		self assert: canvas facts size equals: 1 ]
		ensure: [
			canvas announcer unsubscribe: self.
			AgentRemote disable.
			AgentCanvas reset ]
]

{ #category : 'tests' }
AgentKnowledgeTest >> testInteractiveSandboxFactBackedWidgetUsesLiveValueAndUpdatesOnce [
	| canvas space widget |
	AgentRemote enable.
	canvas := AgentCanvasInteractiveTestProbe new.
	space := AgentCanvasStaleSpaceProbe new.
	canvas space: space.
	AgentCanvas instVarNamed: #current put: canvas.
	[
		AgentFact key: #city body: 'Tokyo'.
		widget := AgentReactiveLifecycleTestWidget new.
		self assert: widget initialCity equals: 'Tokyo'.
		canvas addWidget: widget.
		space runNextTask.
		space runNextTask.
		self assert: widget factReactionCount equals: 0.
		AgentFact key: #city body: 'Lisbon'.
		self assert: widget factReactionCount equals: 0.
		space runNextTask.
		self assert: widget factReactionCount equals: 1.
		AgentFact key: #city body: 'Porto'.
		space runNextTask.
		self assert: widget factReactionCount equals: 2 ]
		ensure: [
			AgentRemote disable.
			AgentCanvas reset ]
]

{ #category : 'tests' }
AgentKnowledgeTest >> testBlurHookIsInert [
	"The blur path must NOT announce (it ran on the UI thread; subscribers
	doing network work froze input). Drift sweep covers manual edits."
	| fact heard |
	heard := OrderedCollection new.
	fact := AgentFact key: #city body: 'Tokyo'.
	AgentCanvas current announcer
		when: AgentFactChanged
		do: [ :evt | heard add: evt key ]
		for: self.
	fact noteBodyEdited.
	self assert: heard isEmpty.
	AgentCanvas current announcer unsubscribe: self
]

{ #category : 'tests' }
AgentKnowledgeTest >> testManualDriftIsDetectedAndSwept [
	| fact heard |
	heard := OrderedCollection new.
	fact := AgentFact key: #city body: 'Tokyo'.
	self deny: fact hasUnannouncedEdit.
	"Simulate a manual edit: text changes without going through body:"
	(fact instVarNamed: #bodyEditor) text: 'Lisbon' asRopedText.
	self assert: fact hasUnannouncedEdit.
	AgentCanvas current announcer
		when: AgentFactChanged
		do: [ :evt | heard add: evt key ]
		for: self.
	AgentCanvas current announcePendingFactEdits.
	self assert: (heard includes: #city).
	self deny: fact hasUnannouncedEdit.
	AgentCanvas current announcer unsubscribe: self
]

{ #category : 'tests' }
AgentKnowledgeTest >> testFocusedFactDraftIsNotPublishedBySweep [
	| canvas space fact editor heard |
	canvas := AgentCanvas current.
	space := BlSpace new.
	canvas instVarNamed: #space put: space.
	space root addChild: canvas ensureContent.
	fact := AgentFact key: #city body: 'Tokyo'.
	heard := OrderedCollection new.
	canvas announcer
		when: AgentFactChanged
		do: [ :evt | heard add: evt key ]
		for: self.
	editor := fact instVarNamed: #bodyEditor.
	editor requestFocus.
	editor text: 'Lis' asRopedText.
	self assert: fact isEditing.
	self deny: fact hasUnannouncedEdit.
	canvas announcePendingFactEdits.
	self assert: heard isEmpty.
	canvas announcer unsubscribe: self
]

{ #category : 'tests' }
AgentKnowledgeTest >> testCanvasClickMakesCompletedFactDraftAvailableToSweep [
	| canvas space fact editor heard clickEvt |
	canvas := AgentCanvas current.
	space := BlSpace new.
	canvas instVarNamed: #space put: space.
	space root addChild: canvas ensureContent.
	fact := AgentFact key: #city body: 'Tokyo'.
	heard := OrderedCollection new.
	canvas announcer
		when: AgentFactChanged
		do: [ :evt |
			evt fact == fact ifTrue: [
				heard add: fact body ] ]
		for: self.
	editor := fact instVarNamed: #bodyEditor.
	editor requestFocus.
	editor text: 'Lisbon' asRopedText.
	clickEvt := BlMouseDownEvent new.
	clickEvt target: fact parent.
	canvas handleMouseDown: clickEvt.
	self deny: fact isEditing.
	self assert: fact hasUnannouncedEdit.
	canvas announcePendingFactEdits.
	self assert: heard asArray equals: #('Lisbon').
	canvas announcePendingFactEdits.
	self assert: heard size equals: 1.
	canvas announcer unsubscribe: self
]

{ #category : 'tests' }
AgentKnowledgeTest >> testWidgetAnnounceChanged [
	| w heard |
	w := AgentWidget new.
	AgentCanvas current addWidget: w.
	heard := OrderedCollection new.
	AgentCanvas current announcer
		when: AgentWidgetChanged
		do: [ :evt | heard add: evt widget ]
		for: self.
	w announceChanged.
	self assert: (heard includes: w).
	AgentCanvas current announcer unsubscribe: self
]

{ #category : 'tests' }
AgentKnowledgeTest >> testPruneStaleSubscriptionsSilencesOffCanvasWidgets [
	| ghost onCanvas ghostFired liveFired |
	ghostFired := false.
	liveFired := false.
	ghost := AgentWidget new.
	"ghost is NOT on the canvas but is subscribed -- a leftover"
	AgentCanvas current announcer
		when: AgentWidgetChanged do: [ :e | ghostFired := true ] for: ghost.
	onCanvas := AgentWidget new.
	AgentCanvas current addWidget: onCanvas.
	AgentCanvas current announcer
		when: AgentWidgetChanged do: [ :e | liveFired := true ] for: onCanvas.
	AgentCanvas current pruneStaleSubscriptions.
	AgentCanvas current announcer announce:
		(AgentWidgetChanged new widget: onCanvas; yourself).
	self assert: liveFired description: 'on-canvas widget still reacts'.
	self deny: ghostFired description: 'off-canvas ghost was pruned'.
	AgentCanvas current announcer unsubscribe: onCanvas
]

{ #category : 'tests' }
AgentKnowledgeTest >> testDeletedWidgetIsUnsubscribed [
	| w fired |
	w := AgentWidget new.
	AgentCanvas current addWidget: w.
	fired := false.
	AgentCanvas current announcer
		when: AgentFactChanged
		do: [ :evt | fired := true ]
		for: w.
	w removeFromParent.
	AgentFact key: #city body: 'Tokyo'.
	self deny: fired
]
