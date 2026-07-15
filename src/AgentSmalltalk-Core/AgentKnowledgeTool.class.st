"
I expose one frozen AgentKnowledgeCatalog snapshot through the gateway's
inspect_knowledge tool. I return compact JSON envelopes whose content fields
are explicitly marked as untrusted data. The catalog owns request-local handles
and bounded projections; I add action-specific result-count limits.
"
Class {
	#name : 'AgentKnowledgeTool',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'limits' }
AgentKnowledgeTool class >> maxReadItems [
	^ 5
]

{ #category : 'limits' }
AgentKnowledgeTool class >> maxKindFilters [
	^ 10
]

{ #category : 'limits' }
AgentKnowledgeTool class >> maxKindNameCharacters [
	^ 32
]

{ #category : 'limits' }
AgentKnowledgeTool class >> maxFactListResults [
	^ 10
]

{ #category : 'limits' }
AgentKnowledgeTool class >> maxQueryCharacters [
	^ 200
]

{ #category : 'limits' }
AgentKnowledgeTool class >> maxSearchResults [
	^ 10
]

{ #category : 'limits' }
AgentKnowledgeTool class >> maxSelectedOverviewItems [
	^ 20
]

{ #category : 'private' }
AgentKnowledgeTool class >> boundedKey: aKey [
	| string limit marker keep |
	string := aKey asString.
	limit := AgentKnowledgeProjection maxLabelCharacters.
	string size <= limit ifTrue: [ ^ string ].
	marker := ' ... [truncated]'.
	keep := limit - marker size.
	^ (string first: keep) , marker
]

{ #category : 'private' }
AgentKnowledgeTool class >> envelopeFor: action items: items [
	^ {
		'schema' -> 'agent-knowledge/v1'.
		'trust' -> 'untrusted-data'.
		'action' -> action.
		'items' -> items asArray } asDictionary
]

{ #category : 'handling' }
AgentKnowledgeTool class >> handle: input using: catalog [
	| action |
	action := input at: 'action' ifAbsent: [ ^ 'ERROR: missing action' ].
	action isString ifFalse: [ ^ 'ERROR: action must be a string' ].
	action = 'overview' ifTrue: [ ^ self overviewUsing: catalog ].
	action = 'list_facts' ifTrue: [ ^ self listFacts: input using: catalog ].
	action = 'search' ifTrue: [ ^ self search: input using: catalog ].
	action = 'read' ifTrue: [ ^ self read: input using: catalog ].
	action = 'get_fact' ifTrue: [ ^ self getFact: input using: catalog ].
	^ 'ERROR: unknown knowledge action'
]

{ #category : 'private' }
AgentKnowledgeTool class >> json: aDictionary [
	^ STONJSON toString: aDictionary
]

{ #category : 'handling' }
AgentKnowledgeTool class >> getFact: input using: catalog [
	| key projection envelope |
	key := input at: 'key' ifAbsent: [ ^ 'ERROR: get_fact requires key' ].
	key := key asString trimBoth.
	key isEmpty ifTrue: [ ^ 'ERROR: get_fact requires non-empty key' ].
	key size > AgentKnowledgeProjection maxLabelCharacters ifTrue: [
		^ 'ERROR: fact key is too long' ].
	projection := catalog factProjectionWithKey: key.
	envelope := self
		envelopeFor: 'get_fact'
		items: (projection
			ifNil: [ #() ]
			ifNotNil: [ { self readDictionaryFor: projection } ]).
	envelope at: 'found' put: projection notNil.
	^ self json: envelope
]

{ #category : 'handling' }
AgentKnowledgeTool class >> listFacts: input using: catalog [
	| offset requestedLimit facts remaining shown envelope |
	offset := input at: 'offset' ifAbsent: [ 0 ].
	(offset isInteger and: [ offset >= 0 ])
		ifFalse: [ ^ 'ERROR: offset must be a non-negative integer' ].
	requestedLimit := input at: 'limit' ifAbsent: [ self maxFactListResults ].
	(requestedLimit isInteger and: [ requestedLimit > 0 ])
		ifFalse: [ ^ 'ERROR: limit must be a positive integer' ].
	requestedLimit := requestedLimit min: self maxFactListResults.
	facts := catalog projectionsOfKind: #fact.
	remaining := offset >= facts size
		ifTrue: [ #() ]
		ifFalse: [ facts allButFirst: offset ].
	shown := remaining first: (remaining size min: requestedLimit).
	envelope := self
		envelopeFor: 'list_facts'
		items: (shown collect: [ :projection |
			self summaryDictionaryFor: projection ]).
	envelope
		at: 'total' put: facts size;
		at: 'offset' put: offset;
		at: 'returned' put: shown size;
		at: 'truncated' put: offset + shown size < facts size.
	(envelope at: 'truncated') ifTrue: [
		envelope at: 'next_offset' put: offset + shown size ].
	^ self json: envelope
]

{ #category : 'handling' }
AgentKnowledgeTool class >> overviewUsing: catalog [
	| counts selected shown failures envelope |
	counts := Dictionary new.
	catalog projections do: [ :projection |
		| kind |
		kind := projection kind asString.
		counts at: kind put: (counts at: kind ifAbsent: [ 0 ]) + 1 ].
	selected := catalog projections select: [ :projection | projection selected ].
	shown := selected first: (selected size min: self maxSelectedOverviewItems).
	failures := catalog projectionFailures.
	envelope := self
		envelopeFor: 'overview'
		items: (shown collect: [ :projection |
			self summaryDictionaryFor: projection ]).
	envelope
		at: 'available' put: counts;
		at: 'total' put: catalog projections size;
		at: 'selected_total' put: selected size;
		at: 'selected_truncated' put: selected size > shown size;
		at: 'projection_failures' put: failures;
		at: 'projection_failures_total' put: catalog projectionFailureCount;
		at: 'projection_failures_truncated'
			put: catalog projectionFailureCount > failures size.
	^ self json: envelope
]

{ #category : 'handling' }
AgentKnowledgeTool class >> read: input using: catalog [
	| handles shown items missing envelope |
	handles := input at: 'handles' ifAbsent: [ ^ 'ERROR: read requires handles' ].
	((handles isCollection) and: [ handles isString not ])
		ifFalse: [ ^ 'ERROR: handles must be an array' ].
	shown := handles first: (handles size min: self maxReadItems).
	items := OrderedCollection new.
	missing := OrderedCollection new.
	shown do: [ :handle |
		(catalog projectionWithHandle: handle)
			ifNil: [ missing add: (self boundedKey: handle) ]
			ifNotNil: [ :projection |
				items add: (self readDictionaryFor: projection) ] ].
	envelope := self envelopeFor: 'read' items: items.
	envelope
		at: 'requested' put: handles size;
		at: 'truncated' put: handles size > shown size;
		at: 'missing_handles' put: missing asArray.
	^ self json: envelope
]

{ #category : 'private' }
AgentKnowledgeTool class >> readDictionaryFor: projection [
	| dictionary |
	dictionary := self summaryDictionaryFor: projection.
	dictionary
		at: 'content' put: projection content;
		at: 'content_truncated' put: projection contentTruncated.
	^ dictionary
]

{ #category : 'handling' }
AgentKnowledgeTool class >> search: input using: catalog [
	| query kinds requestedLimit matches shown envelope |
	query := input at: 'query' ifAbsent: [ ^ 'ERROR: search requires query' ].
	query := query asString trimBoth.
	query isEmpty ifTrue: [ ^ 'ERROR: search requires non-empty query' ].
	query size > self maxQueryCharacters ifTrue: [
		^ 'ERROR: search query is too long' ].
	kinds := input at: 'kinds' ifAbsent: [ #() ].
	((kinds isCollection) and: [ kinds isString not ])
		ifFalse: [ ^ 'ERROR: kinds must be an array' ].
	kinds size > self maxKindFilters ifTrue: [
		^ 'ERROR: too many kind filters' ].
	(kinds allSatisfy: [ :kind |
		kind isString and: [ kind size <= self maxKindNameCharacters ] ])
		ifFalse: [ ^ 'ERROR: invalid kind filter' ].
	requestedLimit := input at: 'limit' ifAbsent: [ 5 ].
	(requestedLimit isInteger and: [ requestedLimit > 0 ])
		ifFalse: [ ^ 'ERROR: limit must be a positive integer' ].
	requestedLimit := requestedLimit min: self maxSearchResults.
	matches := catalog
		search: query
		kinds: kinds
		limit: requestedLimit + 1.
	shown := matches first: (matches size min: requestedLimit).
	envelope := self
		envelopeFor: 'search'
		items: (shown collect: [ :projection |
			self summaryDictionaryFor: projection ]).
	envelope
		at: 'query' put: query;
		at: 'returned' put: shown size;
		at: 'truncated' put: matches size > shown size.
	^ self json: envelope
]

{ #category : 'private' }
AgentKnowledgeTool class >> summaryDictionaryFor: projection [
	| dictionary |
	dictionary := {
		'handle' -> projection handle.
		'kind' -> projection kind asString.
		'label' -> projection label.
		'label_truncated' -> projection labelTruncated.
		'summary' -> projection summary.
		'summary_truncated' -> projection summaryTruncated.
		'selected' -> projection selected } asDictionary.
	projection key ifNotNil: [
		dictionary at: 'key' put: (self boundedKey: projection key) ].
	^ dictionary
]
