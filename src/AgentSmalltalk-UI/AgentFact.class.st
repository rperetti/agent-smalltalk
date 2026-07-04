"
I am a yellow sticky: one durable fact the user wants remembered, living as a
visible object on the canvas. Editing my body IS editing the memory; deleting
me IS forgetting. An optional key gives me an identity: AgentFact key:body:
updates the existing sticky with that key instead of creating a duplicate.
Facts are ALWAYS in the LLM context ('## Known facts').
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
	"Create-or-update: one sticky per key, ever."
	| existing fact |
	existing := AgentCanvas current factWithKey: aSymbol.
	existing ifNotNil: [
		existing body: aString.
		^ existing ].
	fact := self new.
	fact key: aSymbol.
	fact body: aString.
	^ self place: fact
]

{ #category : 'instance creation' }
AgentFact class >> body: aString [
	"A keyless, free-form fact."
	| fact |
	fact := self new.
	fact body: aString.
	^ self place: fact
]

{ #category : 'defaults' }
AgentFact >> stickyColor [
	^ Color fromHexString: 'FFF6BF'
]

{ #category : 'selection' }
AgentFact >> defaultBorder [
	^ BlBorder paint: (Color fromHexString: 'E8D98A') width: 1
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
	key := aSymbol.
	self headerText: 'fact[' , aSymbol asString , ']'
]

{ #category : 'accessing' }
AgentFact >> body: aString [
	super body: aString.
	self announceFactChanged
]

{ #category : 'reactions' }
AgentFact >> noteBodyEdited [
	self announceFactChanged
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
