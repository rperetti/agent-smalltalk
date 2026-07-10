"
I am the abstract sticky: a redesigned card with an edge-to-edge coloured header
chip (icon + category label + x) over a white, editable ToAlbum body. My species
are AgentFact (amber, durable truths, always in context), AgentNote (blue,
answers, context only when selected) and AgentSystemMessage (gray, the system's
own voice, context only when selected). Subclasses override the default* hooks
plus #chipAccent / #chipIconColor for their category colour. Slot names
(headerLabel, bodyEditor) are preserved from the pre-refactor classes so live
instances migrate with their state; #repairChrome rebuilds an old sticky into the
new card.
"
Class {
	#name : 'AgentSticky',
	#superclass : 'AgentWidget',
	#instVars : [
		'headerLabel',
		'bodyEditor',
		'editWired',
		'metaLabel'
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
	self buildHeader.
	self buildBody.
	self buildFooter.
	self applyCardChrome
]

{ #category : 'deleting' }
AgentSticky >> showsDeleteButton [
	"Stickies carry the x in their chip header -- no floating one."
	^ false
]

{ #category : 'defaults' }
AgentSticky >> chipCategory [
	^ self defaultHeaderText asUppercase
]

{ #category : 'selection' }
AgentSticky >> defaultBorder [
	^ self chipCardBorder
]

{ #category : 'initialization' }
AgentSticky >> buildHeader [
	| header |
	header := self chipHeaderElement.
	header addChild: self chipDeleteButton.
	self addChild: header
]

{ #category : 'initialization' }
AgentSticky >> buildBody [
	"A padded white body: an optional muted meta label (the fact key, the note's
	question) above the editable value. #showsMetaLabel gates the meta line."
	| box |
	box := BlElement new.
	box layout: BlLinearLayout vertical.
	box padding: (BlInsets top: 10 right: 12 bottom: 12 left: 12).
	box constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical matchParent ].
	self showsMetaLabel ifTrue: [
		metaLabel := BlTextElement new text: ('' asRopedText fontSize: 11).
		metaLabel opacity: 0.5.
		metaLabel margin: (BlInsets top: 0 right: 0 bottom: 2 left: 0).
		metaLabel constraintsDo: [ :c | c vertical fitContent ].
		box addChild: metaLabel ].
	bodyEditor := ToAlbum new.
	bodyEditor placeholderText: self bodyPlaceholder.
	bodyEditor constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical matchParent ].
	box addChild: bodyEditor.
	self addChild: box.
	self ensureEditAnnouncement
]

{ #category : 'initialization' }
AgentSticky >> buildFooter [
	"Hook: species with a footer override (AgentNote adds Reply, AgentSystemMessage
	a timestamp). Body is matchParent so the footer sits under it."
]

{ #category : 'defaults' }
AgentSticky >> showsMetaLabel [
	"True for cards with a muted meta line above the body (Fact key, Note
	provenance). AgentSystemMessage has none."
	^ true
]

{ #category : 'accessing' }
AgentSticky >> setMetaText: aString [
	metaLabel ifNotNil: [
		metaLabel text: (aString asString asRopedText fontSize: 11) ]
]

{ #category : 'reactions' }
AgentSticky >> ensureEditAnnouncement [
	"Deliberately empty. The blur path announced ON THE UI THREAD, and
	subscribers doing network work froze all input (dead panning, broken
	lasso). Manual edits are detected solely by the canvas drift sweep,
	which always announces from its own background process."
]

{ #category : 'reactions' }
AgentSticky >> noteBodyEdited [
	"No-op kept for compatibility: stickies saved with the old blur handler
	still send this on focus loss; announcing here would run subscribers on
	the UI thread. The drift sweep announces instead."
]

{ #category : 'defaults' }
AgentSticky >> defaultExtent [
	^ 220 @ 120
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
	bodyEditor ifNotNil: [ bodyEditor text: aString asRopedText ]
]

{ #category : 'accessing' }
AgentSticky >> headerText: aString [
	"Legacy no-op path: headerLabel is unused in the redesign (the chip label is
	the static category). Kept so old instances that still send it don't error."
	headerLabel ifNotNil: [ headerLabel text: aString ]
]

{ #category : 'migration' }
AgentSticky >> repairChrome [
	"Rebuild an existing sticky with the redesigned chip chrome. Captures the
	value, tears down the old children, re-runs the new builders, then restores
	the value and any subclass meta/footer state via #restoreAfterRepair. Run
	by AgentCanvas>>migrateAfterUpdate."
	| savedBody |
	savedBody := [ self body ] on: Error do: [ :e | '' ].
	self removeChildren.
	headerLabel := nil.
	bodyEditor := nil.
	metaLabel := nil.
	resizeGrip := nil.
	deleteButton := nil.
	self buildHeader.
	self buildBody.
	self buildFooter.
	self ensureResizeGrip.
	self applyCardChrome.
	self body: savedBody.
	self restoreAfterRepair
]

{ #category : 'migration' }
AgentSticky >> restoreAfterRepair [
	"Hook: subclasses re-apply their meta label / footer after a chrome rebuild."
]

{ #category : 'private' }
AgentSticky >> truncate: aString to: n [
	^ aString size <= n
		ifTrue: [ aString ]
		ifFalse: [ (aString first: n - 3) , '...' ]
]
