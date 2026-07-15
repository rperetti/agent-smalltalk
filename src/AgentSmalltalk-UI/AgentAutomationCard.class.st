"
I am the visible face of one AgentAutomation. I live on the bottom-center
routines shelf. In the redesign I am a white card with a purple SCHEDULED chip
carrying a status badge (the last run's outcome), the routine name in bold, its
purpose muted, an aligned key-value table (Schedule / Next run / Last run /
Uses), and a filled Run now + outline Pause/Resume button row. Deleting me
unregisters the routine; canvas undo restores both this card and the same
registration.
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
		'toggleButton',
		'statusBadge'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'knowledge catalog' }
AgentAutomationCard >> contributesToKnowledgeCatalog [
	"The registered automation contributes the commitment projection."
	^ false
]

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
	self width: 300.
	self minHeight: 200.
	self vFitContent.
	self buildHeader.
	self buildBody.
	self applyCardChrome
]

{ #category : 'deleting' }
AgentAutomationCard >> showsDeleteButton [
	"The x lives in the chip header."
	^ false
]

{ #category : 'defaults' }
AgentAutomationCard >> chipAccent [
	^ Color fromHexString: 'E7DEF4'
]

{ #category : 'defaults' }
AgentAutomationCard >> chipIconColor [
	^ Color fromHexString: 'B29AD0'
]

{ #category : 'defaults' }
AgentAutomationCard >> chipCategory [
	^ 'SCHEDULED'
]

{ #category : 'selection' }
AgentAutomationCard >> defaultBorder [
	^ self chipCardBorder
]

{ #category : 'initialization' }
AgentAutomationCard >> buildHeader [
	| header |
	header := self chipHeaderElement.
	statusBadge := self chipBadge: ''.
	header addChild: statusBadge.
	header addChild: self chipDeleteButton.
	self addChild: header
]

{ #category : 'initialization' }
AgentAutomationCard >> buildBody [
	| box |
	box := BlElement new.
	box layout: BlLinearLayout vertical.
	box padding: (BlInsets top: 10 right: 12 bottom: 12 left: 12).
	box constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	nameLabel := BlTextElement new text: ('routine' asRopedText fontSize: 14; bold).
	nameLabel margin: (BlInsets top: 0 right: 0 bottom: 2 left: 0).
	purposeLabel := self multilineLabel.
	purposeLabel opacity: 0.7.
	purposeLabel margin: (BlInsets top: 0 right: 0 bottom: 8 left: 0).
	scheduleLabel := self multilineLabel.
	nextLabel := self multilineLabel.
	lastLabel := self multilineLabel.
	dependenciesLabel := self multilineLabel.
	box addChild: nameLabel.
	box addChild: purposeLabel.
	box addChild: (self tableRow: 'Schedule' value: scheduleLabel).
	box addChild: (self tableRow: 'Next run' value: nextLabel).
	box addChild: (self tableRow: 'Last run' value: lastLabel).
	box addChild: (self tableRow: 'Uses' value: dependenciesLabel).
	box addChild: self actionsRow.
	self addChild: box
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
AgentAutomationCard >> tableRow: aKey value: aValueLabel [
	"A two-column row: a fixed-width muted key, then the value label."
	| row key |
	row := BlElement new.
	row layout: BlLinearLayout horizontal.
	row margin: (BlInsets top: 2 right: 0 bottom: 0 left: 0).
	row constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	key := BlTextElement new text: (aKey asRopedText fontSize: 11).
	key opacity: 0.5.
	key constraintsDo: [ :c | c horizontal exact: 80 ].
	row addChild: key.
	row addChild: aValueLabel.
	^ row
]

{ #category : 'initialization' }
AgentAutomationCard >> actionsRow [
	| row spacer |
	row := BlElement new.
	row layout: BlLinearLayout horizontal.
	row margin: (BlInsets top: 10 right: 0 bottom: 0 left: 0).
	row constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	runButton := self filledButton: 'Run now (keeps schedule)'.
	runButton addEventHandlerOn: BlClickEvent do: [ :event |
		event consume.
		automation ifNotNil: [ automation runNow ] ].
	spacer := BlElement new.
	spacer constraintsDo: [ :c |
		c horizontal exact: 8.
		c vertical exact: 1 ].
	toggleButton := self outlineButton: 'Resume'.
	toggleButton addEventHandlerOn: BlClickEvent do: [ :event |
		event consume.
		self toggleEnabled ].
	row addChild: runButton.
	row addChild: spacer.
	row addChild: toggleButton.
	^ row
]

{ #category : 'initialization' }
AgentAutomationCard >> filledButton: aString [
	| button |
	button := ToLabel new text: aString.
	button background: self chipIconColor.
	button geometry: (BlRoundedRectangleGeometry cornerRadius: 12).
	button padding: (BlInsets top: 5 right: 12 bottom: 5 left: 12).
	button constraintsDo: [ :c | c vertical fitContent ].
	^ button
]

{ #category : 'initialization' }
AgentAutomationCard >> outlineButton: aString [
	| button |
	button := ToLabel new text: aString.
	button background: Color white.
	button border: (BlBorder paint: self chipIconColor width: 1).
	button geometry: (BlRoundedRectangleGeometry cornerRadius: 12).
	button padding: (BlInsets top: 5 right: 12 bottom: 5 left: 12).
	button constraintsDo: [ :c | c vertical fitContent ].
	^ button
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
	nameLabel text: (automation name asRopedText fontSize: 14; bold).
	purposeLabel text: automation purpose.
	scheduleLabel text: automation schedule describe.
	nextLabel text: (automation nextRun
		ifNil: [ 'not scheduled' ]
		ifNotNil: [ :date | date printString ]).
	lastLabel text: self lastSummary.
	dependenciesLabel text: self dependencySummary.
	statusBadge ifNotNil: [ statusBadge text: self statusText ].
	toggleButton text: (automation enabled
		ifTrue: [ 'Pause' ]
		ifFalse: [ 'Resume' ])
]

{ #category : 'updating' }
AgentAutomationCard >> statusText [
	automation ifNil: [ ^ '' ].
	automation history ifNotEmpty: [ :h | ^ h last status asString ].
	^ automation status asString
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
	super restoredToCanvas.
	automation ifNotNil: [ automation restoreRegistration ]
]

{ #category : 'migration' }
AgentAutomationCard >> repairLayout [
	self minHeight: 200.
	self vFitContent.
	self refresh
]

{ #category : 'resizing' }
AgentAutomationCard >> resizeTo: aPoint [
	"Free resize: grabbing the grip takes explicit control of BOTH width and
	height (dropping the initial vFitContent auto-size). Uses width:/height: so
	the change sticks; the wrapping labels reflow to the new width."
	self width: (aPoint x max: 220).
	self height: (aPoint y max: 140)
]

{ #category : 'agent context' }
AgentAutomationCard >> describe [
	^ automation
		ifNil: [ 'routine card' ]
		ifNotNil: [ automation contextDescription ]
]
