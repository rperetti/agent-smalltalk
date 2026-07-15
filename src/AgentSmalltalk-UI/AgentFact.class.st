"
I am a fact: one durable truth the user wants remembered, living as a visible
object on the canvas. Editing my body IS editing the memory; deleting me IS
forgetting. An optional key gives me an identity: AgentFact key:body: updates the
existing fact with that key instead of creating a duplicate. Facts are ALWAYS in
the LLM context ('## Known facts').

In the redesign I am a white card with an amber FACT chip; my key shows as the
muted meta label over the value in bold. The card chrome is inherited from
AgentSticky/AgentWidget -- I only supply my colours and the value styling.
"
Class {
	#name : 'AgentFact',
	#superclass : 'AgentSticky',
	#instVars : [
		'key',
		'lastAnnouncedBody',
		'logicalBody',
		'renderedBody'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'instance creation' }
AgentFact class >> key: aSymbol body: aString [
	"Create-or-update: one fact per key, ever."
	| existing fact |
	existing := AgentCanvas current factWithKey: aSymbol.
	existing ifNotNil: [
		existing body: aString.
		^ existing ].
	fact := self new.
	fact key: aSymbol.
	fact setBody: aString.
	fact := self place: fact.
	fact announceFactChanged.
	^ fact
]

{ #category : 'instance creation' }
AgentFact class >> body: aString [
	"A keyless, free-form fact."
	| fact |
	fact := self new.
	fact setBody: aString.
	fact := self place: fact.
	fact announceFactChanged.
	^ fact
]

{ #category : 'defaults' }
AgentFact >> defaultExtent [
	^ 240 @ 120
]

{ #category : 'defaults' }
AgentFact >> chipAccent [
	^ Color fromHexString: 'FBEBBE'
]

{ #category : 'defaults' }
AgentFact >> chipIconColor [
	^ Color fromHexString: 'E6C35B'
]

{ #category : 'defaults' }
AgentFact >> defaultHeaderText [
	^ 'fact'
]

{ #category : 'defaults' }
AgentFact >> bodyPlaceholder [
	^ 'fact...'
]

{ #category : 'accessing' }
AgentFact >> key [
	^ key
]

{ #category : 'accessing' }
AgentFact >> key: aSymbol [
	"The key is surfaced as the muted meta label, not in the chip (which always
	reads FACT)."
	key := aSymbol.
	self setMetaText: aSymbol asString
]

{ #category : 'accessing' }
AgentFact >> body: aString [
	"Update the logical value immediately. An interactive canvas renders the
	attached editor and announces only from its UI task; the gateway process
	never mutates an attached Bloc element."
	logicalBody := aString asString.
	AgentCanvas current isInteractive
		ifTrue: [ self runOnUiThread: [
			self renderBodyNow.
			self announceFactChanged ] ]
		ifFalse: [
			self renderBodyNow.
			self announceFactChanged ]
]

{ #category : 'private' }
AgentFact >> setBody: aString [
	"Set a new fact's logical value and render it before placement."
	logicalBody := aString asString.
	self renderBodyNow
]

{ #category : 'private' }
AgentFact >> renderBodyNow [
	| value |
	value := self liveBody.
	bodyEditor ifNotNil: [
		bodyEditor text: (value asRopedText fontSize: 16; bold) ].
	renderedBody := value
]

{ #category : 'accessing' }
AgentFact >> liveBody [
	"The logical value is readable before an interactive attachment pulse."
	^ logicalBody ifNil: [ self body ]
]

{ #category : 'migration' }
AgentFact >> restoreAfterRepair [
	key ifNotNil: [ self setMetaText: key asString ]
]

{ #category : 'reactions' }
AgentFact >> announceFactChanged [
	"A manual editor change is committed here. Programmatic interactive updates
	arrive after #renderBodyNow, so this does not touch the attached editor."
	| displayed |
	displayed := self body.
	(renderedBody isNil or: [ displayed ~= renderedBody ]) ifTrue: [
		logicalBody := displayed.
		renderedBody := displayed ].
	lastAnnouncedBody := self liveBody.
	AgentCanvas current announcer announce:
		(AgentFactChanged new key: key; fact: self; yourself)
]

{ #category : 'reactions' }
AgentFact >> hasUnannouncedEdit [
	"Focused editor text is a draft, not durable fact state. The canvas watcher
	must therefore ignore it until the editor has lost focus and committed it."
	| currentRenderedBody |
	currentRenderedBody := renderedBody ifNil: [ self body ].
	^ self isEditing not and: [ currentRenderedBody ~= self body ]
]

{ #category : 'testing' }
AgentFact >> isEditing [
	^ bodyEditor notNil and: [ bodyEditor hasFocus ]
]

{ #category : 'agent context' }
AgentFact >> describe [
	^ String streamContents: [ :s |
		s << 'fact'.
		key ifNotNil: [ s << '[' << key asString << ']' ].
		s << ': ' << self liveBody ]
]

{ #category : 'knowledge catalog' }
AgentFact >> knowledgeProjectionWithHandle: aHandle selected: isSelected [
	^ AgentKnowledgeProjection
		handle: aHandle
		kind: #fact
		key: key
		label: (key ifNil: [ 'unkeyed fact' ] ifNotNil: [ key asString ])
		summary: self liveBody
		content: self liveBody
		selected: isSelected
		source: self
]
