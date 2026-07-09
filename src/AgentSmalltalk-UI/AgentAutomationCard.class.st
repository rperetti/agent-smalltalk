"
I am the visible face of one AgentAutomation. I live on the bottom-center
routines shelf and show its commitment, schedule, dependencies, state, next
run, and most recent outcome. Deleting me unregisters the routine; canvas undo
restores both this card and the same registration.
"
Class {
	#name : 'AgentAutomationCard',
	#superclass : 'AgentWidget',
	#instVars : [
		'automation',
		'nameLabel',
		'purposeLabel',
		'scheduleLabel',
		'stateLabel',
		'nextLabel',
		'lastLabel',
		'dependenciesLabel',
		'runButton',
		'toggleButton'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'instance creation' }
AgentAutomationCard class >> summonFor: anAutomation [
	| existing card |
	existing := self cardFor: anAutomation.
	existing ifNotNil: [
		existing refresh.
		^ existing ].
	card := self new.
	card automation: anAutomation.
	card position: self nextPosition.
	AgentCanvas current addWidget: card.
	^ card
]

{ #category : 'accessing' }
AgentAutomationCard class >> cardFor: anAutomation [
	^ AgentCanvas current widgets
		detect: [ :widget |
			(widget isKindOf: self)
				and: [ widget automation == anAutomation ] ]
		ifNone: [ nil ]
]

{ #category : 'updating' }
AgentAutomationCard class >> refreshFor: anAutomation [
	(self cardFor: anAutomation)
		ifNotNil: [ :card | card refresh ]
]

{ #category : 'removing' }
AgentAutomationCard class >> removeFor: anAutomation [
	(self cardFor: anAutomation)
		ifNotNil: [ :card | card removeFromParent ]
]

{ #category : 'placement' }
AgentAutomationCard class >> nextPosition [
	| count |
	count := AgentCanvas current widgets count: [ :widget |
		widget isKindOf: self ].
	^ 500 @ 620 + ((count * 18) @ (count * 18))
]

{ #category : 'initialization' }
AgentAutomationCard >> initialize [
	super initialize.
	self width: 280.
	self minHeight: 190.
	self vFitContent.
	self background: (Color fromHexString: 'EAE2F2').
	self border: self defaultBorder.
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 7).
	self padding: (BlInsets all: 10).
	nameLabel := ToLabel new text: 'routine'.
	nameLabel constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	purposeLabel := self multilineLabel.
	scheduleLabel := self multilineLabel.
	stateLabel := self multilineLabel.
	nextLabel := self multilineLabel.
	lastLabel := self multilineLabel.
	dependenciesLabel := self multilineLabel.
	self addChild: nameLabel.
	self addChild: purposeLabel.
	self addChild: scheduleLabel.
	self addChild: stateLabel.
	self addChild: nextLabel.
	self addChild: lastLabel.
	self addChild: dependenciesLabel.
	self buildActions
]

{ #category : 'initialization' }
AgentAutomationCard >> multilineLabel [
	| label |
	label := ToLabel new text: ''.
	label beMultiLine.
	label constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	^ label
]

{ #category : 'initialization' }
AgentAutomationCard >> buildActions [
	| row spacer |
	row := BlElement new.
	row layout: BlLinearLayout horizontal.
	row margin: (BlInsets top: 6).
	row constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	runButton := self actionLabel: 'run now'.
	runButton addEventHandlerOn: BlClickEvent do: [ :event |
		event consume.
		automation ifNotNil: [ automation runNow ] ].
	spacer := BlElement new.
	spacer constraintsDo: [ :c |
		c horizontal exact: 18.
		c vertical exact: 1 ].
	toggleButton := self actionLabel: 'resume'.
	toggleButton addEventHandlerOn: BlClickEvent do: [ :event |
		event consume.
		self toggleEnabled ].
	row addChild: runButton.
	row addChild: spacer.
	row addChild: toggleButton.
	self addChild: row
]

{ #category : 'initialization' }
AgentAutomationCard >> actionLabel: aString [
	| label |
	label := ToLabel new text: aString.
	label background: (Color white alpha: 0.55).
	label geometry: (BlRoundedRectangleGeometry cornerRadius: 4).
	label padding: (BlInsets top: 3 right: 7 bottom: 3 left: 7).
	label constraintsDo: [ :c | c vertical fitContent ].
	^ label
]

{ #category : 'accessing' }
AgentAutomationCard >> automation [
	^ automation
]

{ #category : 'accessing' }
AgentAutomationCard >> automation: anAutomation [
	automation := anAutomation.
	self refresh
]

{ #category : 'updating' }
AgentAutomationCard >> refresh [
	self runOnUiThreadSafely: [ self refreshNow ]
]

{ #category : 'updating' }
AgentAutomationCard >> refreshNow [
	automation ifNil: [ ^ self ].
	nameLabel text: (automation name asRopedText fontSize: 13; bold).
	purposeLabel text: automation purpose.
	scheduleLabel text: 'schedule: ' , automation schedule describe.
	stateLabel text: 'status: ' , automation status asString.
	nextLabel text: 'next: ' , (automation nextRun
		ifNil: [ 'not scheduled' ]
		ifNotNil: [ :date | date printString ]).
	lastLabel text: 'last: ' , self lastSummary.
	dependenciesLabel text: 'uses: ' , self dependencySummary.
	toggleButton text: (automation enabled
		ifTrue: [ 'pause' ]
		ifFalse: [ 'resume' ])
]

{ #category : 'updating' }
AgentAutomationCard >> lastSummary [
	automation history ifEmpty: [ ^ 'never' ].
	^ automation history last describe
]

{ #category : 'updating' }
AgentAutomationCard >> dependencySummary [
	automation dependencies ifEmpty: [ ^ 'none declared' ].
	^ automation dependencies
		inject: ''
		into: [ :all :each |
			all isEmpty
				ifTrue: [ each asString ]
				ifFalse: [ all , ', ' , each asString ] ]
]

{ #category : 'actions' }
AgentAutomationCard >> toggleEnabled [
	automation ifNil: [ ^ self ].
	[ automation enabled
		ifTrue: [ automation pause ]
		ifFalse: [ automation resume ] ]
		on: Error
		do: [ :error |
			AgentSystemMessage
				post: error messageText
				key: ('automationControl-' , automation name) asSymbol ]
]

{ #category : 'actions' }
AgentAutomationCard >> browseSource [
	automation ifNotNil: [ automation class browse ]
]

{ #category : 'deleting' }
AgentAutomationCard >> removedFromCanvas [
	automation ifNotNil: [ automation unregisterFromCard ]
]

{ #category : 'deleting' }
AgentAutomationCard >> restoredToCanvas [
	automation ifNotNil: [ automation restoreRegistration ]
]

{ #category : 'migration' }
AgentAutomationCard >> repairLayout [
	self minHeight: 190.
	self vFitContent.
	self refresh
]

{ #category : 'selection' }
AgentAutomationCard >> defaultBorder [
	^ BlBorder paint: (Color fromHexString: 'B49ACB') width: 1
]

{ #category : 'agent context' }
AgentAutomationCard >> describe [
	^ automation
		ifNil: [ 'routine card' ]
		ifNotNil: [ automation contextDescription ]
]
