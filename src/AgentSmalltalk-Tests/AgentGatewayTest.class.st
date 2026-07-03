"
Offline tests for the gateway: payload shapes and tool plumbing.
No network calls — the live loop is exercised by scripts/smoke-gateway.sh.
"
Class {
	#name : 'AgentGatewayTest',
	#superclass : 'TestCase',
	#instVars : [
		'gateway'
	],
	#category : 'AgentSmalltalk-Tests',
	#package : 'AgentSmalltalk-Tests'
}

{ #category : 'running' }
AgentGatewayTest >> setUp [
	super setUp.
	gateway := AgentGateway new
]

{ #category : 'tests' }
AgentGatewayTest >> testToolDefinitionShapes [
	| tools |
	tools := gateway toolDefinitions.
	self assert: (tools collect: [ :t | t at: 'name' ])
		equals: { 'evaluate_smalltalk'. 'search_image' }.
	self assert: (((tools first at: 'input_schema') at: 'properties') includesKey: 'code').
	self assert: ((tools first at: 'input_schema') at: 'required') equals: #('code').
	self assert: (((tools second at: 'input_schema') at: 'properties') includesKey: 'action')
]

{ #category : 'tests' }
AgentGatewayTest >> testToolDefinitionsAreJsonSerializable [
	self shouldnt: [ STONJSON toString: gateway toolDefinitions ] raise: Error
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolDispatchesToImageSearch [
	| toolUse result |
	toolUse := {
		'id' -> 'tu_s1'.
		'name' -> 'search_image'.
		'input' -> ({ 'action' -> 'find_classes'. 'query' -> 'AgentGateway' } asDictionary) } asDictionary.
	result := gateway runTool: toolUse.
	self assert: ((result at: 'content') includesSubstring: 'AgentGateway')
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolRejectsUnknownTool [
	| toolUse result |
	toolUse := {
		'id' -> 'tu_u1'.
		'name' -> 'launch_missiles'.
		'input' -> Dictionary new } asDictionary.
	result := gateway runTool: toolUse.
	self assert: ((result at: 'content') beginsWith: 'ERROR: unknown tool')
]

{ #category : 'tests' }
AgentGatewayTest >> testFinalTextConcatenatesTextBlocks [
	| content |
	content := {
		{ 'type' -> 'text'. 'text' -> 'Hello ' } asDictionary.
		{ 'type' -> 'tool_use'. 'id' -> 'x'. 'input' -> Dictionary new } asDictionary.
		{ 'type' -> 'text'. 'text' -> 'world' } asDictionary }.
	self assert: (gateway finalTextFrom: content) equals: 'Hello world'
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolEvaluatesAndAnswersToolResult [
	| toolUse result |
	toolUse := {
		'id' -> 'tu_123'.
		'input' -> ({ 'code' -> '3 + 4' } asDictionary) } asDictionary.
	result := gateway runTool: toolUse.
	self assert: (result at: 'type') equals: 'tool_result'.
	self assert: (result at: 'tool_use_id') equals: 'tu_123'.
	self assert: (result at: 'content') equals: 'RESULT: 7'
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolFeedsErrorBack [
	| toolUse result |
	toolUse := {
		'id' -> 'tu_err'.
		'input' -> ({ 'code' -> '1 zork' } asDictionary) } asDictionary.
	result := gateway runTool: toolUse.
	self assert: ((result at: 'content') beginsWith: 'ERROR:')
]

{ #category : 'tests' }
AgentGatewayTest >> testLogLinesArePersistedToFile [
	| marker |
	marker := 'test-marker-' , DateAndTime now asUnixTime printString.
	gateway logAdd: marker.
	self assert: (gateway log includes: marker).
	self assert: (AgentGateway logFile contents includesSubstring: marker)
]

{ #category : 'tests' }
AgentGatewayTest >> testSystemPromptIncludesCribSheet [
	self assert: (gateway systemPrompt includesSubstring: 'AgentWidget')
]
