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
		'lastAnnouncedBody'
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
	"Update an already-live fact and announce the new value. New facts use
	#setBody: before placement, then announce after they are discoverable through
	AgentKnowledge."
	self setBody: aString.
	self announceFactChanged
]

{ #category : 'private' }
AgentFact >> setBody: aString [
	"Render the value without announcing. Creation places the fact before its
	first announcement so subscribers can resolve it through AgentKnowledge."
	bodyEditor ifNotNil: [
		bodyEditor text: (aString asString asRopedText fontSize: 16; bold) ].
]

{ #category : 'migration' }
AgentFact >> restoreAfterRepair [
	key ifNotNil: [ self setMetaText: key asString ]
]

{ #category : 'reactions' }
AgentFact >> announceFactChanged [
	lastAnnouncedBody := self body.
	AgentCanvas current announcer announce:
		(AgentFactChanged new key: key; fact: self; yourself)
]

{ #category : 'reactions' }
AgentFact >> hasUnannouncedEdit [
	"True when the editor's text has drifted from what was last announced
	-- i.e. a manual edit that no event delivered."
	^ lastAnnouncedBody ~= self body
]

{ #category : 'agent context' }
AgentFact >> describe [
	^ String streamContents: [ :s |
		s << 'fact'.
		key ifNotNil: [ s << '[' << key asString << ']' ].
		s << ': ' << self body ]
]
