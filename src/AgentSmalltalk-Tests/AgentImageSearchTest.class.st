Class {
	#name : 'AgentImageSearchTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-Tests',
	#package : 'AgentSmalltalk-Tests'
}

{ #category : 'tests' }
AgentImageSearchTest >> testFindClasses [
	| result |
	result := AgentImageSearch handle:
		({ 'action' -> 'find_classes'. 'query' -> 'AgentSandbox' } asDictionary).
	self assert: (result includesSubstring: 'AgentSandbox')
]

{ #category : 'tests' }
AgentImageSearchTest >> testFindClassesNoMatch [
	| result |
	result := AgentImageSearch handle:
		({ 'action' -> 'find_classes'. 'query' -> 'ZorbleWumpus' } asDictionary).
	self assert: (result beginsWith: 'No classes match')
]

{ #category : 'tests' }
AgentImageSearchTest >> testFindSelectors [
	| result |
	result := AgentImageSearch handle:
		({ 'action' -> 'find_selectors'. 'class_name' -> 'AgentSandbox'. 'query' -> 'evalu' } asDictionary).
	self assert: (result includesSubstring: 'evaluate:')
]

{ #category : 'tests' }
AgentImageSearchTest >> testFindSelectorsUnknownClass [
	| result |
	result := AgentImageSearch handle:
		({ 'action' -> 'find_selectors'. 'class_name' -> 'NoSuchClassHere' } asDictionary).
	self assert: (result beginsWith: 'ERROR: no class named')
]

{ #category : 'tests' }
AgentImageSearchTest >> testMethodSource [
	| result |
	result := AgentImageSearch handle:
		({ 'action' -> 'method_source'. 'class_name' -> 'AgentSandbox'. 'query' -> 'safePrint:' } asDictionary).
	self assert: (result includesSubstring: 'printString')
]

{ #category : 'tests' }
AgentImageSearchTest >> testMethodSourceClassSide [
	| result |
	result := AgentImageSearch handle:
		({ 'action' -> 'method_source'. 'class_name' -> 'AgentGateway class'. 'query' -> 'ask:' } asDictionary).
	self assert: (result includesSubstring: 'run:')
]

{ #category : 'tests' }
AgentImageSearchTest >> testUnknownAction [
	| result |
	result := AgentImageSearch handle:
		({ 'action' -> 'frobnicate' } asDictionary).
	self assert: (result beginsWith: 'ERROR: unknown action')
]
