"
I am a transient, bounded view of one live knowledge-bearing object. I do not
own or persist knowledge: facts, widgets, tools, and automations remain the
source of truth. A catalog creates me for one local query or gateway run and
then discards me.
"
Class {
	#name : 'AgentKnowledgeProjection',
	#superclass : 'Object',
	#instVars : [
		'handle',
		'kind',
		'key',
		'label',
		'labelTruncated',
		'summary',
		'content',
		'summaryTruncated',
		'contentTruncated',
		'selected',
		'source'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'limits' }
AgentKnowledgeProjection class >> maxContentCharacters [
	^ 2000
]

{ #category : 'limits' }
AgentKnowledgeProjection class >> maxLabelCharacters [
	^ 120
]

{ #category : 'limits' }
AgentKnowledgeProjection class >> maxSummaryCharacters [
	^ 240
]

{ #category : 'instance creation' }
AgentKnowledgeProjection class >> handle: aHandle kind: aKind key: aKey label: aLabel summary: aSummary content: someContent selected: isSelected source: anObject [
	^ self new
		initializeHandle: aHandle
		kind: aKind
		key: aKey
		label: aLabel
		summary: aSummary
		content: someContent
		selected: isSelected
		source: anObject
]

{ #category : 'private' }
AgentKnowledgeProjection >> boundedString: aValue to: aLimit [
	| string marker keep |
	string := aValue ifNil: [ '' ] ifNotNil: [ aValue asString ].
	string size <= aLimit ifTrue: [ ^ string ].
	marker := ' ... [truncated]'.
	keep := (aLimit - marker size) max: 0.
	^ (string first: keep) , (marker last: aLimit - keep)
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> content [
	^ content
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> contentTruncated [
	^ contentTruncated
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> handle [
	^ handle
]

{ #category : 'initialization' }
AgentKnowledgeProjection >> initializeHandle: aHandle kind: aKind key: aKey label: aLabel summary: aSummary content: someContent selected: isSelected source: anObject [
	| rawSummary rawContent |
	handle := aHandle asString.
	kind := aKind asSymbol.
	key := aKey.
	label := aLabel ifNil: [ kind asString ] ifNotNil: [ aLabel asString ].
	labelTruncated := label size > self class maxLabelCharacters.
	label := self boundedString: label to: self class maxLabelCharacters.
	rawSummary := aSummary ifNil: [ '' ] ifNotNil: [ aSummary asString ].
	rawContent := someContent ifNil: [ '' ] ifNotNil: [ someContent asString ].
	summaryTruncated := rawSummary size > self class maxSummaryCharacters.
	contentTruncated := rawContent size > self class maxContentCharacters.
	summary := self boundedString: rawSummary to: self class maxSummaryCharacters.
	content := self boundedString: rawContent to: self class maxContentCharacters.
	selected := isSelected == true.
	source := anObject
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> key [
	^ key
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> kind [
	^ kind
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> label [
	^ label
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> labelTruncated [
	^ labelTruncated
]

{ #category : 'searching' }
AgentKnowledgeProjection >> matchRankFor: aQuery [
	| query keyText labelText |
	query := aQuery ifNil: [ '' ] ifNotNil: [ aQuery asString trimBoth asLowercase ].
	query isEmpty ifTrue: [ ^ nil ].
	keyText := key ifNil: [ '' ] ifNotNil: [ key asString asLowercase ].
	labelText := label asLowercase.
	(keyText = query or: [ labelText = query ]) ifTrue: [ ^ 1 ].
	((keyText beginsWith: query) or: [ labelText beginsWith: query ]) ifTrue: [ ^ 2 ].
	(self searchText includesSubstring: query) ifTrue: [ ^ 3 ].
	^ nil
]

{ #category : 'private' }
AgentKnowledgeProjection >> searchText [
	| text |
	text := String streamContents: [ :stream |
		key ifNotNil: [ stream << key asString; space ].
		stream
			<< label;
			space;
			<< summary;
			space;
			<< content ].
	^ text asLowercase
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> selected [
	^ selected
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> source [
	"The live source is local-only implementation state. Serializers must expose
	only the copied fields above."
	^ source
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> summary [
	^ summary
]

{ #category : 'accessing' }
AgentKnowledgeProjection >> summaryTruncated [
	^ summaryTruncated
]
