"
I am the visible face of an AgentTool: a card in the bottom-right toolbox corner
(facts top-left, notes top-right, system bottom-left, tools bottom-right -- the
canvas geography completed). In the redesign I am a white card with a green
SERVICE chip, the tool's name in bold, and its purpose muted below. Right-click
opens the TOOL class's source so a human can read and tweak it, and the fix
benefits every reuse. I am meta (a handle on a capability, not a capability
myself), so I stay out of the LLM's widget context -- the tool itself is listed
under '## Capabilities you've built'.
"
Class {
	#name : 'AgentToolCard',
	#superclass : 'AgentWidget',
	#instVars : [
		'toolClass',
		'nameLabel',
		'purposeLabel'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'instance creation' }
AgentToolCard class >> summonFor: aToolClass [
	"One card per tool: return the existing card if there is one, else make
	and place a new one in the toolbox pile."
	| existing card |
	existing := AgentCanvas current widgets
		detect: [ :w | (w isKindOf: self) and: [ w toolClass == aToolClass ] ]
		ifNone: [ nil ].
	existing ifNotNil: [ ^ existing ].
	card := self new.
	card toolClass: aToolClass.
	card position: self nextPosition.
	AgentCanvas current addWidget: card.
	^ card
]

{ #category : 'instance creation' }
AgentToolCard class >> nextPosition [
	"Pile in the bottom-right toolbox corner."
	| n |
	n := AgentCanvas current widgets count: [ :w | w isKindOf: self ].
	^ (940 + (n * 16)) @ (600 + (n * 22))
]

{ #category : 'initialization' }
AgentToolCard >> initialize [
	super initialize.
	self width: 260.
	self minHeight: 96.
	self vFitContent.
	self buildHeader.
	self buildBody.
	self applyCardChrome
]

{ #category : 'deleting' }
AgentToolCard >> showsDeleteButton [
	"The x lives in the chip header."
	^ false
]

{ #category : 'defaults' }
AgentToolCard >> chipAccent [
	^ Color fromHexString: 'DBEDD2'
]

{ #category : 'defaults' }
AgentToolCard >> chipIconColor [
	^ Color fromHexString: '8FC08A'
]

{ #category : 'defaults' }
AgentToolCard >> chipCategory [
	^ 'SERVICE'
]

{ #category : 'selection' }
AgentToolCard >> defaultBorder [
	^ self chipCardBorder
]

{ #category : 'initialization' }
AgentToolCard >> buildHeader [
	| header |
	header := self chipHeaderElement.
	header addChild: self chipDeleteButton.
	self addChild: header
]

{ #category : 'initialization' }
AgentToolCard >> buildBody [
	| box |
	box := BlElement new.
	box layout: BlLinearLayout vertical.
	box padding: (BlInsets top: 10 right: 12 bottom: 12 left: 12).
	box constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	nameLabel := BlTextElement new text: ('tool' asRopedText fontSize: 14; bold).
	nameLabel margin: (BlInsets top: 0 right: 0 bottom: 4 left: 0).
	purposeLabel := ToLabel new text: ''.
	purposeLabel opacity: 0.7.
	purposeLabel beMultiLine.
	purposeLabel constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	box addChild: nameLabel.
	box addChild: purposeLabel.
	self addChild: box
]

{ #category : 'migration' }
AgentToolCard >> repairLayout [
	"Repair cards created before purpose text wrapped -- IN PLACE, so callers
	holding the same purposeLabel (and the migration test) see it fixed. Match-
	parent also makes horizontal resizing useful instead of leaving the label at
	a fixed width."
	self minHeight: 96.
	self vFitContent.
	purposeLabel ifNotNil: [
		purposeLabel beMultiLine.
		purposeLabel constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ] ]
]

{ #category : 'resizing' }
AgentToolCard >> resizeTo: aPoint [
	"Free resize: grabbing the grip takes explicit control of BOTH width and
	height, dropping the initial width: + vFitContent auto-size. Uses width:/
	height: (which set the size constraints) rather than the base extent:, so
	the change actually sticks; the matchParent purpose label re-wraps to the
	new width instead of being clipped."
	self width: (aPoint x max: 160).
	self height: (aPoint y max: 96)
]

{ #category : 'accessing' }
AgentToolCard >> toolClass [
	^ toolClass
]

{ #category : 'accessing' }
AgentToolCard >> toolClass: aClass [
	toolClass := aClass.
	nameLabel text: (aClass name asRopedText fontSize: 14; bold).
	purposeLabel text: (aClass purpose ifNil: [ '' ])
]

{ #category : 'actions' }
AgentToolCard >> browseSource [
	"Right-click opens the TOOL's source, not this card's."
	toolClass ifNotNil: [ toolClass browse ]
]

{ #category : 'agent context' }
AgentToolCard >> describe [
	^ 'tool card for ' , (toolClass ifNil: [ '?' ] ifNotNil: [ :t | t name ])
]

{ #category : 'knowledge catalog' }
AgentToolCard >> contributesToKnowledgeCatalog [
	"The underlying tool contributes the capability projection."
	^ false
]
