"
I am a blue note: the agent's answer as an object on the canvas. Unlike
AgentFact (durable truths, always in context), I am conversation residue --
deletable paper. I do NOT feed the LLM context by default; lasso me to make
a follow-up question about my content. The question I answer shows as my muted
meta line (provenance), and a Reply footer continues the thread from here.
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
	^ 220 @ 150
]

{ #category : 'defaults' }
AgentNote >> chipAccent [
	^ Color fromHexString: 'D6E6F7'
]

{ #category : 'defaults' }
AgentNote >> chipIconColor [
	^ Color fromHexString: '84A9D6'
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
	self setMetaText: 're: ' , (self truncate: aString to: 40)
]

{ #category : 'migration' }
AgentNote >> restoreAfterRepair [
	question ifNotNil: [
		self setMetaText: 're: ' , (self truncate: question to: 40) ]
]

{ #category : 'initialization' }
AgentNote >> buildFooter [
	"A Reply button under the note: continue the conversation from here.
	Pure form -- it just selects this note (scoping the LLM context to its
	Q+A, via phase-3 selection) and opens the spotlight. The follow-up
	answer then lands as a new note beside this one (AgentNote nextPosition
	places near the selection), so threads grow spatially, not as a log."
	| footer reply |
	footer := BlElement new.
	footer layout: BlLinearLayout horizontal.
	footer padding: (BlInsets top: 0 right: 12 bottom: 10 left: 12).
	footer constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	reply := ToLabel new text: '↩ reply'.
	reply opacity: 0.7.
	reply constraintsDo: [ :c | c vertical fitContent ].
	reply addEventHandlerOn: BlClickEvent do: [ :evt |
		evt consume.
		self reply ].
	footer addChild: reply.
	self addChild: footer
]

{ #category : 'actions' }
AgentNote >> reply [
	"Select this note (scopes context to it) and open the spotlight for a
	follow-up. Guarded for headless: selection still happens; the spotlight
	needs a live space."
	| canvas |
	canvas := AgentCanvas current.
	canvas selectWidgets: { self }.
	canvas isOpen ifTrue: [ AgentSpotlight openOn: canvas ]
]

{ #category : 'agent context' }
AgentNote >> describe [
	^ String streamContents: [ :s |
		s << 'note'.
		question ifNotNil: [ s << ' re: ''' << question << '''' ].
		s << ' -- ' << (self truncate: self body to: 160) ]
]
