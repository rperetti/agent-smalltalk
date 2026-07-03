"
I am a sticky note: one durable fact the user wants remembered, living as a
visible object on the canvas. My body is editable in place (editing the text
IS editing the memory) and deleting me IS forgetting. An optional key gives
me an identity: AgentFact key:body: updates the existing sticky with that key
instead of creating a duplicate.
"
Class {
	#name : 'AgentFact',
	#superclass : 'AgentWidget',
	#instVars : [
		'key',
		'keyLabel',
		'bodyEditor'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'instance creation' }
AgentFact class >> key: aSymbol body: aString [
	"Create-or-update: one sticky per key, ever."
	| existing fact |
	existing := AgentCanvas current factWithKey: aSymbol.
	existing ifNotNil: [
		existing body: aString.
		^ existing ].
	fact := self new.
	fact key: aSymbol.
	fact body: aString.
	fact position: self nextPilePosition.
	AgentCanvas current addWidget: fact.
	^ fact
]

{ #category : 'instance creation' }
AgentFact class >> body: aString [
	"A keyless, free-form fact."
	| fact |
	fact := self new.
	fact body: aString.
	fact position: self nextPilePosition.
	AgentCanvas current addWidget: fact.
	^ fact
]

{ #category : 'instance creation' }
AgentFact class >> nextPilePosition [
	"Loose pile near the top-left corner."
	| n |
	n := AgentCanvas current facts size.
	^ (20 + (n * 16)) @ (20 + (n * 26))
]

{ #category : 'initialization' }
AgentFact >> initialize [
	| header spacer deleteButton |
	super initialize.
	self extent: 190 @ 110.
	self background: (Color fromHexString: 'FFF6BF').
	self border: (BlBorder paint: (Color fromHexString: 'E8D98A') width: 1).
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 4).
	self padding: (BlInsets all: 8).
	header := BlElement new.
	header layout: BlLinearLayout horizontal.
	header constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	keyLabel := ToLabel new text: 'fact'.
	spacer := BlElement new.
	spacer constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical exact: 1 ].
	deleteButton := BlTextElement new text: ('x' asRopedText fontSize: 14).
	deleteButton addEventHandlerOn: BlClickEvent do: [ :evt |
		evt consume.
		self removeFromParent ].
	header addChild: keyLabel.
	header addChild: spacer.
	header addChild: deleteButton.
	bodyEditor := ToAlbum new.
	bodyEditor placeholderText: 'fact...'.
	bodyEditor constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical matchParent ].
	self addChild: header.
	self addChild: bodyEditor
]

{ #category : 'accessing' }
AgentFact >> key [
	^ key
]

{ #category : 'accessing' }
AgentFact >> key: aSymbol [
	key := aSymbol.
	keyLabel text: 'fact[' , aSymbol asString , ']'
]

{ #category : 'accessing' }
AgentFact >> body [
	"Read from the editor so in-place user edits count."
	^ bodyEditor text asString
]

{ #category : 'accessing' }
AgentFact >> body: aString [
	bodyEditor text: aString asRopedText
]

{ #category : 'agent context' }
AgentFact >> describe [
	^ String streamContents: [ :s |
		s << 'fact'.
		key ifNotNil: [ s << '[' << key asString << ']' ].
		s << ': ' << self body ]
]
