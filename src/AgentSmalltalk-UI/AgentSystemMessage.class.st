"
I am a gray system card: the system's own voice. I announce things the user did
NOT initiate -- 'tooling updated', a swallowed error -- and pile at the
bottom-left corner. Deleting me is acknowledging me. Repeated messages with the
same key coalesce into one card (my footer shows the time and 'x3') instead of
stacking. I am out of the LLM context unless lassoed. I am the seed of the
future inbox (see docs/ideas.md: agent-initiated work).
"
Class {
	#name : 'AgentSystemMessage',
	#superclass : 'AgentSticky',
	#instVars : [
		'key',
		'count',
		'stamp',
		'footerLabel',
		'failureOccurrencesDelivered'
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
AgentSystemMessage >> chipAccent [
	^ Color fromHexString: 'E8E8E5'
]

{ #category : 'defaults' }
AgentSystemMessage >> chipIconColor [
	^ Color fromHexString: 'B9B9B3'
]

{ #category : 'defaults' }
AgentSystemMessage >> defaultHeaderText [
	^ 'system'
]

{ #category : 'defaults' }
AgentSystemMessage >> bodyPlaceholder [
	^ 'system message'
]

{ #category : 'defaults' }
AgentSystemMessage >> showsMetaLabel [
	"The system card puts its time/count in a footer, not a meta line."
	^ false
]

{ #category : 'initialization' }
AgentSystemMessage >> buildFooter [
	footerLabel := BlTextElement new text: ('' asRopedText fontSize: 10).
	footerLabel opacity: 0.5.
	footerLabel margin: (BlInsets top: 0 right: 12 bottom: 10 left: 12).
	footerLabel constraintsDo: [ :c | c vertical fitContent ].
	self addChild: footerLabel.
	self refreshFooter
]

{ #category : 'updating' }
AgentSystemMessage >> refreshFooter [
	footerLabel ifNil: [ ^ self ].
	footerLabel text: (self footerText asRopedText fontSize: 10)
]

{ #category : 'updating' }
AgentSystemMessage >> footerText [
	^ String streamContents: [ :s |
		stamp ifNotNil: [ s << stamp ].
		self count > 1 ifTrue: [ s << '  ·  x' << self count printString ] ]
]

{ #category : 'migration' }
AgentSystemMessage >> restoreAfterRepair [
	self refreshFooter
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

{ #category : 'async failure delivery' }
AgentSystemMessage >> failureOccurrencesDelivered [
	"The delivery cursor belongs to this durable/coalescing card, not to a
	particular AgentGateway instance. A missing slot means no occurrence has
	been delivered yet, including for instances migrated from older images."
	^ failureOccurrencesDelivered ifNil: [ 0 ]
]

{ #category : 'async failure delivery' }
AgentSystemMessage >> markFailureOccurrencesDelivered [
	failureOccurrencesDelivered := self count
]

{ #category : 'accessing' }
AgentSystemMessage >> message: aString [
	count := (count ifNil: [ 0 ]) + 1.
	stamp := Time now print24 first: 5.
	self body: aString.
	self refreshFooter
]

{ #category : 'accessing' }
AgentSystemMessage >> coalesce: aString [
	"Update the existing card AND raise it to the front -- a repeat announcement
	the user should still notice, not one buried behind whatever was raised
	since."
	self message: aString.
	self raise
]

{ #category : 'agent context' }
AgentSystemMessage >> describe [
	^ String streamContents: [ :s |
		s << 'system'.
		key ifNotNil: [ s << '[' << key asString << ']' ].
		s << ': ' << (self truncate: self body to: 160).
		self count > 1 ifTrue: [ s << ' (x' << self count printString << ')' ] ]
]

{ #category : 'knowledge catalog' }
AgentSystemMessage >> knowledgeProjectionWithHandle: aHandle selected: isSelected [
	^ AgentKnowledgeProjection
		handle: aHandle
		kind: #diagnostic
		key: key
		label: (key ifNil: [ 'system message' ] ifNotNil: [ key asString ])
		summary: self describe
		content: self body
		selected: isSelected
		source: self
]
