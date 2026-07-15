"
I build an ephemeral, typed view over knowledge already owned by the live
image. I keep no registry and write no state. Each instance snapshots the
currently available sources, assigns request-local handles, and supports
bounded, deterministic local search.
"
Class {
	#name : 'AgentKnowledgeCatalog',
	#superclass : 'Object',
	#instVars : [
		'projections',
		'projectionFailures',
		'projectionFailureCount'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'instance creation' }
AgentKnowledgeCatalog class >> snapshot [
	^ self new
]

{ #category : 'limits' }
AgentKnowledgeCatalog class >> maxSearchResults [
	^ 20
]

{ #category : 'limits' }
AgentKnowledgeCatalog class >> maxProjectionFailures [
	^ 10
]

{ #category : 'private' }
AgentKnowledgeCatalog >> addCanvasSourcesTo: sources [
	| canvasClass canvas widgets selected |
	canvasClass := Smalltalk globals at: #AgentCanvas ifAbsent: [ ^ self ].
	canvas := canvasClass current.
	widgets := canvas widgets asOrderedCollection.
	canvas facts do: [ :fact |
		(widgets includes: fact) ifFalse: [ widgets add: fact ] ].
	selected := canvas selectedWidgets.
	widgets do: [ :widget | sources add: { widget. (selected includes: widget) } ]
]

{ #category : 'private' }
AgentKnowledgeCatalog >> addCoreSourcesTo: sources [
	(Smalltalk globals at: #AgentTool ifAbsent: [ nil ])
		ifNotNil: [ :toolClass |
			toolClass tools do: [ :tool | sources add: { tool. false } ] ].
	(Smalltalk globals at: #AgentAutomation ifAbsent: [ nil ])
		ifNotNil: [ :automationClass |
			automationClass automations do: [ :automation |
				sources add: { automation. false } ] ]
]

{ #category : 'initialization' }
AgentKnowledgeCatalog >> initialize [
	super initialize.
	self rebuild
]

{ #category : 'private' }
AgentKnowledgeCatalog >> liveSources [
	| sources |
	sources := OrderedCollection new.
	self addCanvasSourcesTo: sources.
	self addCoreSourcesTo: sources.
	^ sources
]

{ #category : 'accessing' }
AgentKnowledgeCatalog >> factProjectionWithKey: aKey [
	| wanted |
	wanted := aKey ifNil: [ '' ] ifNotNil: [ aKey asString asLowercase ].
	^ projections
		detect: [ :projection |
			projection kind = #fact and: [
				projection key notNil and: [
					projection key asString asLowercase = wanted ] ] ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
AgentKnowledgeCatalog >> projectionWithHandle: aString [
	^ projections
		detect: [ :projection | projection handle = aString asString ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
AgentKnowledgeCatalog >> projectionForSource: anObject [
	^ projections
		detect: [ :projection | projection source == anObject ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
AgentKnowledgeCatalog >> projections [
	^ projections asArray
]

{ #category : 'accessing' }
AgentKnowledgeCatalog >> projectionsOfKind: aSymbol [
	^ self projections select: [ :projection | projection kind = aSymbol asSymbol ]
]

{ #category : 'accessing' }
AgentKnowledgeCatalog >> projectionFailureCount [
	^ projectionFailureCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
AgentKnowledgeCatalog >> projectionFailures [
	^ projectionFailures
		ifNil: [ #() ]
		ifNotNil: [
			(projectionFailures collect: [ :failure | failure copy ]) asArray ]
]

{ #category : 'private' }
AgentKnowledgeCatalog >> boundedFailureText: aValue [
	| string limit marker keep |
	string := aValue ifNil: [ '' ] ifNotNil: [ aValue asString ].
	limit := AgentKnowledgeProjection maxSummaryCharacters.
	string size <= limit ifTrue: [ ^ string ].
	marker := ' ... [truncated]'.
	keep := limit - marker size.
	^ (string first: keep) , marker
]

{ #category : 'private' }
AgentKnowledgeCatalog >> recordProjectionFailureFor: source at: sourceIndex error: error [
	projectionFailureCount := self projectionFailureCount + 1.
	projectionFailures size >= self class maxProjectionFailures ifTrue: [ ^ self ].
	projectionFailures add: ({
		'source_index' -> sourceIndex.
		'source_class' -> (self boundedFailureText: source class name).
		'error_class' -> error class name.
		'message' -> (self boundedFailureText: error messageText) } asDictionary)
]

{ #category : 'initialization' }
AgentKnowledgeCatalog >> rebuild [
	| nextHandle sourceIndex |
	projections := OrderedCollection new.
	projectionFailures := OrderedCollection new.
	projectionFailureCount := 0.
	nextHandle := 1.
	sourceIndex := 0.
	self liveSources do: [ :sourceAndSelection |
		| source selected projection |
		sourceIndex := sourceIndex + 1.
		source := sourceAndSelection first.
		selected := sourceAndSelection second.
		[ ((source respondsTo: #contributesToKnowledgeCatalog)
				and: [ source contributesToKnowledgeCatalog ]) ifTrue: [
				projection := source
					knowledgeProjectionWithHandle: 'K' , nextHandle printString
					selected: selected.
				projections add: projection.
				nextHandle := nextHandle + 1 ] ]
			on: Error
			do: [ :error |
				self
					recordProjectionFailureFor: source
					at: sourceIndex
					error: error ] ]
]

{ #category : 'searching' }
AgentKnowledgeCatalog >> search: aQuery [
	^ self search: aQuery kinds: #() limit: 10
]

{ #category : 'searching' }
AgentKnowledgeCatalog >> search: aQuery kinds: kinds limit: requestedLimit [
	| kindNames matches sorted count |
	kindNames := kinds
		ifNil: [ #() ]
		ifNotNil: [ kinds collect: [ :kind | kind asString asLowercase ] ].
	matches := self projections select: [ :projection |
		(kindNames isEmpty or: [
			kindNames includes: projection kind asString asLowercase ])
			and: [ (projection matchRankFor: aQuery) notNil ] ].
	sorted := matches asSortedCollection: [ :left :right |
		| leftRank rightRank leftLabel rightLabel |
		leftRank := left matchRankFor: aQuery.
		rightRank := right matchRankFor: aQuery.
		leftRank = rightRank
			ifFalse: [ leftRank < rightRank ]
			ifTrue: [
				leftLabel := left label asLowercase.
				rightLabel := right label asLowercase.
				leftLabel = rightLabel
					ifTrue: [ left handle < right handle ]
					ifFalse: [ leftLabel < rightLabel ] ] ].
	count := requestedLimit ifNil: [ 10 ].
	count := (count max: 0) min: self class maxSearchResults.
	count := count min: sorted size.
	count = 0 ifTrue: [ ^ #() ].
	^ sorted asArray first: count
]
