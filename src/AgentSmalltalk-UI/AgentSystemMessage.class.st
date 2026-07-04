"
I am a gray sticky: the system's own voice. I announce things the user did
NOT initiate -- 'tooling updated', a swallowed error -- and pile at the
bottom-left corner. Deleting me is acknowledging me. Repeated messages with
the same key coalesce into one sticky ('system x3 14:32') instead of
stacking. I am out of the LLM context unless lassoed. I am the seed of the
future inbox (see docs/ideas.md: agent-initiated work).
"
Class {
	#name : 'AgentSystemMessage',
	#superclass : 'AgentSticky',
	#instVars : [
		'key',
		'count'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'posting' }
AgentSystemMessage class >> post: aString [
	^ self post: aString key: nil
]

{ #category : 'posting' }
AgentSystemMessage class >> post: aString key: aSymbolOrNil [
	| existing message |
	aSymbolOrNil ifNotNil: [
		existing := AgentCanvas current systemMessages
			detect: [ :m | m key = aSymbolOrNil ] ifNone: [ nil ].
		existing ifNotNil: [ ^ existing coalesce: aString ] ].
	message := self new.
	message key: aSymbolOrNil.
	message message: aString.
	^ self place: message
]

{ #category : 'placement' }
AgentSystemMessage class >> pileOrigin [
	"Bottom-left corner: facts top-left, notes top-right, system here."
	^ 20 @ 640
]

{ #category : 'defaults' }
AgentSystemMessage >> stickyColor [
	^ Color fromHexString: 'E8E8E5'
]

{ #category : 'selection' }
AgentSystemMessage >> defaultBorder [
	^ BlBorder paint: (Color fromHexString: 'B9B9B3') width: 1
]

{ #category : 'defaults' }
AgentSystemMessage >> defaultHeaderText [
	^ 'system'
]

{ #category : 'defaults' }
AgentSystemMessage >> bodyPlaceholder [
	^ 'system message'
]

{ #category : 'accessing' }
AgentSystemMessage >> key [
	^ key
]

{ #category : 'accessing' }
AgentSystemMessage >> key: aSymbolOrNil [
	key := aSymbolOrNil
]

{ #category : 'accessing' }
AgentSystemMessage >> count [
	^ count ifNil: [ 1 ]
]

{ #category : 'accessing' }
AgentSystemMessage >> message: aString [
	count := (count ifNil: [ 0 ]) + 1.
	self body: aString.
	self headerText: (String streamContents: [ :s |
		s << 'system'.
		self count > 1 ifTrue: [ s << ' x' << self count printString ].
		s << ' ' << (Time now print24 first: 5) ])
]

{ #category : 'accessing' }
AgentSystemMessage >> coalesce: aString [
	self message: aString
]

{ #category : 'agent context' }
AgentSystemMessage >> describe [
	^ String streamContents: [ :s |
		s << 'system'.
		key ifNotNil: [ s << '[' << key asString << ']' ].
		s << ': ' << (self truncate: self body to: 160).
		self count > 1 ifTrue: [ s << ' (x' << self count printString << ')' ] ]
]
