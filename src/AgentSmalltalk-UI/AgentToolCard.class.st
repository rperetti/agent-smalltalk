"
I am the visible face of an AgentTool: a small sage card in the bottom-right
toolbox corner (facts top-left, notes top-right, system bottom-left, tools
bottom-right -- the canvas geography completed). I show the tool's name and
purpose; right-click opens the TOOL class's source so a human can read and
tweak it, and the fix benefits every reuse. I am meta (a handle on a
capability, not a capability myself), so I stay out of the LLM's widget
context -- the tool itself is listed under '## Capabilities you've built'.
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
	self extent: 200 @ 84.
	self background: (Color fromHexString: 'E4EAD9').
	self border: (BlBorder paint: (Color fromHexString: 'B6C39E') width: 1).
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 4).
	self padding: (BlInsets all: 8).
	nameLabel := BlTextElement new text: ('tool' asRopedText fontSize: 13).
	purposeLabel := ToLabel new text: ''.
	purposeLabel constraintsDo: [ :c | c horizontal exact: 184 ].
	self addChild: nameLabel.
	self addChild: purposeLabel
]

{ #category : 'accessing' }
AgentToolCard >> toolClass [
	^ toolClass
]

{ #category : 'accessing' }
AgentToolCard >> toolClass: aClass [
	toolClass := aClass.
	nameLabel text: (aClass name asRopedText fontSize: 13; bold).
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
