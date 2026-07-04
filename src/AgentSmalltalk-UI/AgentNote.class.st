"
I am a pale-blue note: the agent's answer as an object on the canvas.
Unlike AgentFact (durable truths, always in context), I am conversation
residue -- deletable paper. I do NOT feed the LLM context by default; lasso
me to make a follow-up question about my content. My header records the
question I answer (provenance); my body is editable like any sticky.
"
Class {
	#name : 'AgentNote',
	#superclass : 'AgentWidget',
	#instVars : [
		'question',
		'headerLabel',
		'bodyEditor'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'instance creation' }
AgentNote class >> question: qString answer: aString [
	| note |
	note := self new.
	note question: qString.
	note body: aString.
	note position: self nextPosition.
	AgentCanvas current addWidget: note.
	^ note
]

{ #category : 'instance creation' }
AgentNote class >> nextPosition [
	"Near the selection when there is one (the answer belongs to what was
	asked about); otherwise a pile near the top-right, mirroring the facts
	pile at the top-left."
	| canvas sel n |
	canvas := AgentCanvas current.
	sel := canvas selectedWidgets.
	sel notEmpty ifTrue: [ ^ sel last position + (260 @ 0) ].
	n := canvas notes size.
	^ (940 + (n * 16)) @ (20 + (n * 26))
]

{ #category : 'initialization' }
AgentNote >> initialize [
	| header spacer deleteButton |
	super initialize.
	self extent: 210 @ 130.
	self background: (Color fromHexString: 'DCE9F7').
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 4).
	self padding: (BlInsets all: 8).
	header := BlElement new.
	header layout: BlLinearLayout horizontal.
	header constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	headerLabel := ToLabel new text: 'note'.
	spacer := BlElement new.
	spacer constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical exact: 1 ].
	deleteButton := BlTextElement new text: ('x' asRopedText fontSize: 14).
	deleteButton addEventHandlerOn: BlClickEvent do: [ :evt |
		evt consume.
		self removeFromParent ].
	header addChild: headerLabel.
	header addChild: spacer.
	header addChild: deleteButton.
	bodyEditor := ToAlbum new.
	bodyEditor placeholderText: 'note...'.
	bodyEditor constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical matchParent ].
	self addChild: header.
	self addChild: bodyEditor
]

{ #category : 'selection' }
AgentNote >> defaultBorder [
	^ BlBorder paint: (Color fromHexString: '9FBEDC') width: 1
]

{ #category : 'accessing' }
AgentNote >> question [
	^ question
]

{ #category : 'accessing' }
AgentNote >> question: aString [
	question := aString.
	headerLabel text: 're: ' , (self truncate: aString to: 32)
]

{ #category : 'accessing' }
AgentNote >> body [
	"Read from the editor so in-place user edits count."
	^ bodyEditor text asString
]

{ #category : 'accessing' }
AgentNote >> body: aString [
	bodyEditor text: aString asRopedText
]

{ #category : 'private' }
AgentNote >> truncate: aString to: n [
	^ aString size <= n
		ifTrue: [ aString ]
		ifFalse: [ (aString first: n - 3) , '...' ]
]

{ #category : 'agent context' }
AgentNote >> describe [
	^ String streamContents: [ :s |
		s << 'note'.
		question ifNotNil: [ s << ' re: ''' << question << '''' ].
		s << ' -- ' << (self truncate: self body to: 160) ]
]
