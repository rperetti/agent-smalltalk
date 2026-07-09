"
I am the explicit outcome of an automation run. An unchanged result stays
quiet; a changed result may become a system message. This keeps notification
policy deterministic instead of asking the scheduler to compare arbitrary
objects and guess what mattered.
"
Class {
	#name : 'AgentAutomationResult',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'summary'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'instance creation' }
AgentAutomationResult class >> unchanged [
	^ self unchanged: 'completed'
]

{ #category : 'instance creation' }
AgentAutomationResult class >> unchanged: aString [
	^ self new
		kind: #unchanged;
		summary: aString;
		yourself
]

{ #category : 'instance creation' }
AgentAutomationResult class >> changed: aString [
	^ self new
		kind: #changed;
		summary: aString;
		yourself
]

{ #category : 'accessing' }
AgentAutomationResult >> kind: aSymbol [
	kind := aSymbol
]

{ #category : 'accessing' }
AgentAutomationResult >> summary: aString [
	summary := aString asString
]

{ #category : 'accessing' }
AgentAutomationResult >> kind [
	^ kind
]

{ #category : 'accessing' }
AgentAutomationResult >> summary [
	^ summary ifNil: [ '' ]
]

{ #category : 'testing' }
AgentAutomationResult >> isChanged [
	^ kind = #changed
]

{ #category : 'printing' }
AgentAutomationResult >> printOn: aStream [
	aStream
		nextPutAll: kind asString;
		nextPutAll: ': ';
		nextPutAll: self summary
]
