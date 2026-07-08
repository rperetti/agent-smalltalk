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
AgentGatewayTest >> testBudgetNoteAppendedWhenRoundsRunLow [
	| results |
	gateway maxRounds: 20.
	results := gateway
		appendBudgetNoteTo: { { 'content' -> 'RESULT: ok' } asDictionary }
		afterRound: 18.
	self assert: ((results last at: 'content') includesSubstring: 'only 2 tool round').
	self assert: ((results last at: 'content') beginsWith: 'RESULT: ok')
]

{ #category : 'tests' }
AgentGatewayTest >> testNoBudgetNoteEarlyOrAtEnd [
	| early atEnd |
	gateway maxRounds: 20.
	early := gateway
		appendBudgetNoteTo: { { 'content' -> 'RESULT: ok' } asDictionary }
		afterRound: 5.
	atEnd := gateway
		appendBudgetNoteTo: { { 'content' -> 'RESULT: ok' } asDictionary }
		afterRound: 20.
	self assert: (early last at: 'content') equals: 'RESULT: ok'.
	self assert: (atEnd last at: 'content') equals: 'RESULT: ok'
]

{ #category : 'tests' }
AgentGatewayTest >> testSystemPromptIncludesBasePrompt [
	self assert: (gateway systemPrompt includesSubstring: 'AgentWidget')
]

{ #category : 'tests' }
AgentGatewayTest >> testScriptedTransportExercisesCompleteToolLoop [
	| transport result secondRequest toolResult |
	transport := AgentGatewayFakeTransport responses: {
		{ 'content' -> {
			{ 'type' -> 'tool_use'.
				'id' -> 'tu_loop'.
				'name' -> 'evaluate_smalltalk'.
				'input' -> ({ 'code' -> '3 + 4' } asDictionary) } asDictionary
			} } asDictionary.
		{ 'content' -> {
			{ 'type' -> 'text'. 'text' -> 'calculated seven' } asDictionary
			} } asDictionary }.
	gateway
		transport: transport;
		apiKey: 'test-key';
		maxRounds: 10.
	result := gateway run: 'calculate three plus four'.
	self assert: result equals: 'calculated seven'.
	self assert: transport payloads size equals: 2.
	secondRequest := transport payloads second.
	toolResult := ((secondRequest at: 'messages') last at: 'content') first.
	self assert: (toolResult at: 'tool_use_id') equals: 'tu_loop'.
	self assert: (toolResult at: 'content') equals: 'RESULT: 7'
]
