"
I am the abstract sticky: a small card with a header row (label + x-to-delete)
and an editable ToAlbum body. My species are AgentFact (yellow, durable
truths, always in context), AgentNote (blue, answers, context only when
selected) and AgentSystemMessage (gray, the system's own voice, context only
when selected). Subclasses override the default* hooks and stickyColor.
Slot names (headerLabel, bodyEditor) are preserved from the pre-refactor
classes so live instances migrate with their state.
"
Class {
	#name : 'AgentSticky',
	#superclass : 'AgentWidget',
	#instVars : [
		'headerLabel',
		'bodyEditor',
		'editWired'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'placement' }
AgentSticky class >> pileOrigin [
	^ 20 @ 20
]

{ #category : 'placement' }
AgentSticky class >> nextPilePosition [
	| n |
	n := AgentCanvas current widgets count: [ :w | w isKindOf: self ].
	^ self pileOrigin + ((n * 16) @ (n * 26))
]

{ #category : 'placement' }
AgentSticky class >> place: aSticky [
	aSticky position: self nextPilePosition.
	AgentCanvas current addWidget: aSticky.
	^ aSticky
]

{ #category : 'initialization' }
AgentSticky >> initialize [
	super initialize.
	self extent: self defaultExtent.
	self background: self stickyColor.
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 4).
	self padding: (BlInsets all: 8).
	self buildHeader.
	self buildBody
]

{ #category : 'initialization' }
AgentSticky >> buildHeader [
	| header spacer deleteButton |
	header := BlElement new.
	header layout: BlLinearLayout horizontal.
	header constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	headerLabel := ToLabel new text: self defaultHeaderText.
	"Width-capped so a long header can never push the x off the card."
	headerLabel constraintsDo: [ :c | c horizontal exact: 160 ].
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
	self addChild: header
]

{ #category : 'initialization' }
AgentSticky >> buildBody [
	bodyEditor := ToAlbum new.
	bodyEditor placeholderText: self bodyPlaceholder.
	bodyEditor constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical matchParent ].
	self addChild: bodyEditor.
	self ensureEditAnnouncement
]

{ #category : 'reactions' }
AgentSticky >> ensureEditAnnouncement [
	"Manual edits announce when the user clicks away (focus loss) -- chosen
	over Album's editor-internal change events for reliability. Idempotent
	for the update migration."
	editWired == true ifTrue: [ ^ self ].
	bodyEditor ifNil: [ ^ self ].
	bodyEditor addEventHandlerOn: BlBlurEvent do: [ :evt | self noteBodyEdited ].
	editWired := true
]

{ #category : 'reactions' }
AgentSticky >> noteBodyEdited [
	"Hook: species that broadcast their changes override (AgentFact does)."
]

{ #category : 'defaults' }
AgentSticky >> defaultExtent [
	^ 190 @ 110
]

{ #category : 'defaults' }
AgentSticky >> stickyColor [
	^ Color veryLightGray
]

{ #category : 'defaults' }
AgentSticky >> defaultHeaderText [
	^ 'sticky'
]

{ #category : 'defaults' }
AgentSticky >> bodyPlaceholder [
	^ '...'
]

{ #category : 'accessing' }
AgentSticky >> body [
	"Read from the editor so in-place user edits count."
	^ bodyEditor text asString
]

{ #category : 'accessing' }
AgentSticky >> body: aString [
	bodyEditor text: aString asRopedText
]

{ #category : 'accessing' }
AgentSticky >> headerText: aString [
	headerLabel ifNotNil: [ headerLabel text: aString ]
]

{ #category : 'private' }
AgentSticky >> truncate: aString to: n [
	^ aString size <= n
		ifTrue: [ aString ]
		ifFalse: [ (aString first: n - 3) , '...' ]
]
