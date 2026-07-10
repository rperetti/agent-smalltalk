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
AgentGatewayTest >> testRunToolRejectsInventedFactValueDuringWidgetRequest [
	| fact toolUse result |
	[
		AgentCanvas reset.
		fact := AgentFact key: #city body: 'Lisbon'.
		toolUse := {
			'id' -> 'tu_fact_reject'.
			'input' -> ({ 'code' -> 'AgentFact key: #city body: ''Porto''' } asDictionary) }
			asDictionary.
		result := gateway
			runTool: toolUse
			forUserRequest: 'Create a City Watch card that displays my saved city.'.
		self assert: ((result at: 'content') beginsWith: 'ERROR: fact write rejected').
		self assert: fact body equals: 'Lisbon' ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testGatewayRunPreservesFactDuringCityWatchRequest [
	| fact transport result secondRequest toolResult |
	[
		AgentCanvas reset.
		fact := AgentFact key: #city body: 'Lisbon'.
		transport := AgentGatewayFakeTransport responses: {
			{ 'content' -> {
				{ 'type' -> 'tool_use'.
					'id' -> 'tu_city_watch'.
					'name' -> 'evaluate_smalltalk'.
					'input' -> ({ 'code' -> 'AgentFact key: #city body: ''Porto''' } asDictionary) }
					asDictionary
				} } asDictionary.
			{ 'content' -> {
				{ 'type' -> 'text'. 'text' -> 'I left your saved city unchanged.' } asDictionary
				} } asDictionary }.
		gateway
			transport: transport;
			apiKey: 'test-key';
			maxRounds: 2.
		result := gateway run: 'Create a City Watch card that displays my saved city.'.
		self assert: result equals: 'I left your saved city unchanged.'.
		self assert: fact body equals: 'Lisbon'.
		secondRequest := transport payloads second.
		toolResult := ((secondRequest at: 'messages') last at: 'content') first.
		self assert: ((toolResult at: 'content') beginsWith: 'ERROR: fact write rejected') ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolAllowsFactValueExplicitlySuppliedByUser [
	| fact toolUse result |
	[
		AgentCanvas reset.
		fact := AgentFact key: #city body: 'Lisbon'.
		toolUse := {
			'id' -> 'tu_fact_allow'.
			'input' -> ({ 'code' -> 'AgentFact key: #city body: ''Porto''' } asDictionary) }
			asDictionary.
		result := gateway
			runTool: toolUse
			forUserRequest: 'I moved to Porto. Remember that my city is Porto.'.
		self assert: ((result at: 'content') beginsWith: 'RESULT:').
		self assert: fact body equals: 'Porto' ]
		ensure: [ AgentCanvas reset ]
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
AgentGatewayTest >> testBudgetNoteExplainsWhenToolsAreExhausted [
	| atEnd |
	gateway maxRounds: 20.
	atEnd := gateway
		appendBudgetNoteTo: { { 'content' -> 'RESULT: ok' } asDictionary }
		afterRound: 20.
	self assert: ((atEnd last at: 'content') includesSubstring: 'tool-round budget is exhausted').
	self assert: ((atEnd last at: 'content') includesSubstring: 'No more tools are available')
]

{ #category : 'tests' }
AgentGatewayTest >> testNoBudgetNoteEarly [
	| early |
	gateway maxRounds: 20.
	early := gateway
		appendBudgetNoteTo: { { 'content' -> 'RESULT: ok' } asDictionary }
		afterRound: 5.
	self assert: (early last at: 'content') equals: 'RESULT: ok'
]

{ #category : 'tests' }
AgentGatewayTest >> testSystemPromptIncludesBasePrompt [
	self assert: (gateway systemPrompt includesSubstring: 'AgentWidget')
]

{ #category : 'tests' }
AgentGatewayTest >> testSystemPromptRequiresFactFirstReferenceResolution [
	| prompt |
	prompt := gateway systemPrompt.
	self assert: (prompt includesSubstring: 'Resolve references from facts before you design or code').
	self assert: (prompt includesSubstring: 'Facts stated in the CURRENT request').
	self assert: (prompt includesSubstring: 'count immediately').
	self assert: (prompt includesSubstring: 'keep it fact-backed').
	self assert: (prompt includesSubstring: 'copying the current literal').
	self assert: (prompt includesSubstring: 'AgentKnowledge at:')
]

{ #category : 'tests' }
AgentGatewayTest >> testSystemPromptRequiresNonblockingWidgetConstruction [
	| prompt |
	prompt := gateway systemPrompt.
	self assert: (prompt includesSubstring: 'Never perform network or other slow I/O synchronously').
	self assert: (prompt includesSubstring: 'initialize` may end with `self refreshAsync`').
	self assert: (prompt includesSubstring: 'self runOnUiThreadSafely:').
	self assert: (prompt includesSubstring: 'agent-widget-').
	self assert: (prompt includesSubstring: 'inspect and clean it up instead of blindly constructing another').
	self assert: (prompt includesSubstring: 'setText:on:fontSize:').
	self assert: (prompt includesSubstring: 'Never send `text:fontSize:` directly')
]

{ #category : 'tests' }
AgentGatewayTest >> testSystemPromptDefinesSafeAutomationContract [
	| prompt |
	prompt := gateway systemPrompt.
	self assert: (prompt includesSubstring: 'Scheduled automations').
	self assert: (prompt includesSubstring: 'scheduled run never invokes the LLM').
	self assert: (prompt includesSubstring: 'registerOn:dependencies:').
	self assert: (prompt includesSubstring: 'verifyAndEnable').
	self assert: (prompt includesSubstring: 'runAutomatedAction').
	self assert: (prompt includesSubstring: 'AgentAutomationResult unchanged:').
	self assert: (prompt includesSubstring: 'Deleting the card unregisters')
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

{ #category : 'tests' }
AgentGatewayTest >> testFinalPermittedToolRoundGetsToolsDisabledFinishingResponse [
	| transport result finalPayload toolResult |
	transport := AgentGatewayFakeTransport responses: {
		{ 'content' -> {
			{ 'type' -> 'tool_use'.
				'id' -> 'tu_boundary'.
				'name' -> 'evaluate_smalltalk'.
				'input' -> ({ 'code' -> '6 * 7' } asDictionary) } asDictionary
			} } asDictionary.
		{ 'content' -> {
			{ 'type' -> 'text'. 'text' -> 'calculated forty-two at the boundary' } asDictionary
			} } asDictionary }.
	gateway
		transport: transport;
		apiKey: 'test-key';
		maxRounds: 1.
	result := gateway run: 'calculate six times seven'.
	self assert: result equals: 'calculated forty-two at the boundary'.
	self assert: transport payloads size equals: 2.
	finalPayload := transport payloads second.
	self deny: (finalPayload includesKey: 'tools').
	toolResult := ((finalPayload at: 'messages') last at: 'content') first.
	self assert: (toolResult at: 'tool_use_id') equals: 'tu_boundary'.
	self assert: ((toolResult at: 'content') includesSubstring: 'RESULT: 42').
	self assert: ((toolResult at: 'content') includesSubstring: 'No more tools are available')
]

{ #category : 'tests' }
AgentGatewayTest >> testFinalToolResultIsReportedWhenFinishingResponseFails [
	| transport result |
	transport := AgentGatewayFakeTransport responses: {
		{ 'content' -> {
			{ 'type' -> 'tool_use'.
				'id' -> 'tu_report'.
				'name' -> 'evaluate_smalltalk'.
				'input' -> ({ 'code' -> '40 + 2' } asDictionary) } asDictionary
			} } asDictionary }.
	gateway
		transport: transport;
		apiKey: 'test-key';
		maxRounds: 1.
	result := gateway run: 'calculate forty plus two'.
	self assert: (result includesSubstring: 'final model response was unavailable').
	self assert: (result includesSubstring: 'RESULT: 42')
]
