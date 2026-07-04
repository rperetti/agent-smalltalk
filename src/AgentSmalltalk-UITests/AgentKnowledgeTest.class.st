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
AgentKnowledgeTest >> testManualEditHookAnnounces [
	| fact heard |
	heard := OrderedCollection new.
	fact := AgentFact key: #city body: 'Tokyo'.
	AgentCanvas current announcer
		when: AgentFactChanged
		do: [ :evt | heard add: evt key ]
		for: self.
	fact noteBodyEdited.
	self assert: (heard includes: #city).
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
