"
I am the null-object for missing knowledge: AgentKnowledge answers me when a
fact is absent. I remember WHICH key was missing, test as isUnknown (every
other object answers false via the Object extension), and print safely for
labels. My protocol is deliberately minimal -- anything beyond testing and
printing fails loudly, so unknowns cannot propagate invisibly through
computations.
"
Class {
	#name : 'AgentUnknown',
	#superclass : 'Object',
	#instVars : [
		'key'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'instance creation' }
AgentUnknown class >> key: aSymbol [
	^ self new setKey: aSymbol
]

{ #category : 'initialization' }
AgentUnknown >> setKey: aSymbol [
	key := aSymbol
]

{ #category : 'accessing' }
AgentUnknown >> key [
	^ key
]

{ #category : 'testing' }
AgentUnknown >> isUnknown [
	^ true
]

{ #category : 'printing' }
AgentUnknown >> asString [
	^ key
		ifNil: [ 'unknown' ]
		ifNotNil: [ 'unknown (' , key asString , ')' ]
]

{ #category : 'printing' }
AgentUnknown >> printOn: aStream [
	aStream nextPutAll: self asString
]
