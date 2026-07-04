"
I am a blue sticky: the agent's answer as an object on the canvas. Unlike
AgentFact (durable truths, always in context), I am conversation residue --
deletable paper. I do NOT feed the LLM context by default; lasso me to make
a follow-up question about my content. My header records the question I
answer (provenance).
"
Class {
	#name : 'AgentNote',
	#superclass : 'AgentSticky',
	#instVars : [
		'question'
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

{ #category : 'placement' }
AgentNote class >> pileOrigin [
	^ 940 @ 20
]

{ #category : 'placement' }
AgentNote class >> nextPosition [
	"Near the selection when there is one (the answer belongs to what was
	asked about); otherwise the top-right pile, mirroring the facts pile."
	| sel |
	sel := AgentCanvas current selectedWidgets.
	sel notEmpty ifTrue: [ ^ sel last position + (260 @ 0) ].
	^ self nextPilePosition
]

{ #category : 'defaults' }
AgentNote >> defaultExtent [
	^ 210 @ 130
]

{ #category : 'defaults' }
AgentNote >> stickyColor [
	^ Color fromHexString: 'DCE9F7'
]

{ #category : 'selection' }
AgentNote >> defaultBorder [
	^ BlBorder paint: (Color fromHexString: '9FBEDC') width: 1
]

{ #category : 'defaults' }
AgentNote >> defaultHeaderText [
	^ 'note'
]

{ #category : 'defaults' }
AgentNote >> bodyPlaceholder [
	^ 'note...'
]

{ #category : 'accessing' }
AgentNote >> question [
	^ question
]

{ #category : 'accessing' }
AgentNote >> question: aString [
	question := aString.
	self headerText: 're: ' , (self truncate: aString to: 32)
]

{ #category : 'private' }
AgentNote >> repairHeader [
	"Kept for migrations of notes built before the header width cap."
	headerLabel ifNotNil: [
		headerLabel constraintsDo: [ :c | c horizontal exact: 160 ] ]
]

{ #category : 'agent context' }
AgentNote >> describe [
	^ String streamContents: [ :s |
		s << 'note'.
		question ifNotNil: [ s << ' re: ''' << question << '''' ].
		s << ' -- ' << (self truncate: self body to: 160) ]
]
