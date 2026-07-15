"
Offline tests for the gateway: payload shapes, tool plumbing, and evaluation
metrics. No network calls — live behavior is exercised explicitly by
./evaluate.sh.
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
		equals: { 'evaluate_smalltalk'. 'search_image'. 'inspect_knowledge' }.
	self assert: (((tools first at: 'input_schema') at: 'properties') includesKey: 'code').
	self assert: ((tools first at: 'input_schema') at: 'required') equals: #('code').
	self assert: (((tools second at: 'input_schema') at: 'properties') includesKey: 'action').
	self assert: (((tools third at: 'input_schema') at: 'properties') includesKey: 'action').
	self assert: ((((tools third at: 'input_schema') at: 'properties') at: 'action') at: 'enum')
		equals: #('overview' 'search' 'read' 'get_fact')
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
AgentGatewayTest >> testInspectKnowledgeUsesFrozenSnapshot [
	| firstUse secondUse first second fresh |
	[
		AgentCanvas reset.
		AgentFact key: #city body: 'Tokyo'.
		firstUse := {
			'id' -> 'tu_knowledge_first'.
			'name' -> 'inspect_knowledge'.
			'input' -> ({ 'action' -> 'get_fact'. 'key' -> 'CITY' } asDictionary) }
			asDictionary.
		first := STONJSON fromString: ((gateway runTool: firstUse) at: 'content').
		self assert: (first at: 'trust') equals: 'untrusted-data'.
		self assert: (first at: 'found').
		self assert: (((first at: 'items') first at: 'content')) equals: 'Tokyo'.

		AgentFact key: #country body: 'Portugal'.
		secondUse := {
			'id' -> 'tu_knowledge_second'.
			'name' -> 'inspect_knowledge'.
			'input' -> ({ 'action' -> 'get_fact'. 'key' -> 'country' } asDictionary) }
			asDictionary.
		second := STONJSON fromString: ((gateway runTool: secondUse) at: 'content').
		self deny: (second at: 'found').

		fresh := STONJSON fromString:
			(((AgentGateway new runTool: secondUse) at: 'content')).
		self assert: (fresh at: 'found').
		self assert: (((fresh at: 'items') first at: 'content')) equals: 'Portugal' ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testInspectKnowledgeOverviewCountsAndSummarizesSelection [
	| note toolUse overview available selectedItem |
	[
		AgentCanvas reset.
		AgentFact key: #city body: 'Tokyo'.
		note := AgentNote question: 'Trip plan' answer: 'Visit the gardens'.
		AgentCanvas current selectWidgets: { note }.
		toolUse := {
			'id' -> 'tu_knowledge_overview'.
			'name' -> 'inspect_knowledge'.
			'input' -> ({ 'action' -> 'overview' } asDictionary) } asDictionary.
		overview := STONJSON fromString: ((gateway runTool: toolUse) at: 'content').
		available := overview at: 'available'.
		self assert: (available at: 'fact') equals: 1.
		self assert: (available at: 'note') equals: 1.
		self assert: (overview at: 'selected_total') equals: 1.
		self deny: (overview at: 'selected_truncated').
		selectedItem := (overview at: 'items') first.
		self assert: (selectedItem at: 'kind') equals: 'note'.
		self assert: (selectedItem at: 'selected') ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testInspectKnowledgeSearchAndReadAreBounded [
	| body searchUse search readUse read item |
	[
		AgentCanvas reset.
		body := String new: 3000 withAll: $x.
		AgentFact key: #knowledgeToolLargeFact body: body.
		searchUse := {
			'id' -> 'tu_knowledge_search'.
			'name' -> 'inspect_knowledge'.
			'input' -> ({
				'action' -> 'search'.
				'query' -> 'knowledgeToolLargeFact'.
				'kinds' -> #('fact').
				'limit' -> 1 } asDictionary) } asDictionary.
		search := STONJSON fromString: ((gateway runTool: searchUse) at: 'content').
		self assert: (search at: 'returned') equals: 1.
		self deny: (((search at: 'items') first) includesKey: 'content').

		readUse := {
			'id' -> 'tu_knowledge_read'.
			'name' -> 'inspect_knowledge'.
			'input' -> ({
				'action' -> 'read'.
				'handles' -> { ((search at: 'items') first at: 'handle') } } asDictionary) }
			asDictionary.
		read := STONJSON fromString: ((gateway runTool: readUse) at: 'content').
		item := (read at: 'items') first.
		self assert: (item at: 'content_truncated').
		self assert: (item at: 'content') size
			equals: AgentKnowledgeProjection maxContentCharacters.
		self assert: ((item at: 'content') endsWith: '[truncated]') ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testInspectKnowledgeClampsResultCounts [
	| searchUse search handles readUse read |
	[
		AgentCanvas reset.
		1 to: 12 do: [ :index |
			AgentFact
				key: ('boundedKnowledge' , index printString) asSymbol
				body: 'shared bounded knowledge match' ].
		searchUse := {
			'id' -> 'tu_knowledge_clamped_search'.
			'name' -> 'inspect_knowledge'.
			'input' -> ({
				'action' -> 'search'.
				'query' -> 'shared bounded knowledge match'.
				'kinds' -> #('fact').
				'limit' -> 99 } asDictionary) } asDictionary.
		search := STONJSON fromString: ((gateway runTool: searchUse) at: 'content').
		self assert: (search at: 'returned') equals: AgentKnowledgeTool maxSearchResults.
		self assert: (search at: 'truncated').
		handles := (search at: 'items') collect: [ :item | item at: 'handle' ].
		readUse := {
			'id' -> 'tu_knowledge_clamped_read'.
			'name' -> 'inspect_knowledge'.
			'input' -> ({ 'action' -> 'read'. 'handles' -> handles } asDictionary) }
			asDictionary.
		read := STONJSON fromString: ((gateway runTool: readUse) at: 'content').
		self assert: (read at: 'requested') equals: AgentKnowledgeTool maxSearchResults.
		self assert: (read at: 'items') size equals: AgentKnowledgeTool maxReadItems.
		self assert: (read at: 'truncated') ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testInspectKnowledgeRejectsMalformedBounds [
	| result |
	result := gateway runTool: ({
		'id' -> 'tu_knowledge_bad_limit'.
		'name' -> 'inspect_knowledge'.
		'input' -> ({
			'action' -> 'search'.
			'query' -> 'anything'.
			'limit' -> 0 } asDictionary) } asDictionary).
	self assert: (result at: 'content') equals: 'ERROR: limit must be a positive integer'.
	result := gateway runTool: ({
		'id' -> 'tu_knowledge_bad_handles'.
		'name' -> 'inspect_knowledge'.
		'input' -> ({ 'action' -> 'read'. 'handles' -> 'K1' } asDictionary) }
		asDictionary).
	self assert: (result at: 'content') equals: 'ERROR: handles must be an array'
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
AgentGatewayTest >> testRunToolAllowsKeylessFactValueExplicitlySuppliedByUser [
	| toolUse result |
	[
		AgentCanvas reset.
		toolUse := {
			'id' -> 'tu_keyless_fact_allow'.
			'input' -> ({ 'code' -> 'AgentFact body: ''I prefer espresso''' } asDictionary) }
			asDictionary.
		result := gateway
			runTool: toolUse
			forUserRequest: 'Remember that I prefer espresso.'.
		self assert: ((result at: 'content') beginsWith: 'RESULT:').
		self assert: AgentCanvas current facts size equals: 1.
		self assert: AgentCanvas current facts first body equals: 'I prefer espresso' ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolRejectsConcatenatedFactValueBeforeEvaluation [
	| fact toolUse result |
	[
		AgentCanvas reset.
		fact := AgentFact key: #city body: 'Lisbon'.
		toolUse := {
			'id' -> 'tu_fact_concat_reject'.
			'input' -> ({ 'code' -> 'AgentFact key: #city body: ''Porto'' , '' Alegre''' } asDictionary) }
			asDictionary.
		result := gateway
			runTool: toolUse
			forUserRequest: 'Use Porto when configuring the widget.'.
		self assert: ((result at: 'content') beginsWith: 'ERROR: fact write rejected').
		self assert: fact body equals: 'Lisbon'.
		self assert: AgentCanvas current facts size equals: 1 ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolRejectsDynamicFactValueBeforeEvaluation [
	| fact toolUse result |
	[
		AgentCanvas reset.
		fact := AgentFact key: #city body: 'Lisbon'.
		toolUse := {
			'id' -> 'tu_fact_dynamic_reject'.
			'input' -> ({ 'code' -> 'AgentFact key: #city body: (AgentKnowledge at: #city)' } asDictionary) }
			asDictionary.
		result := gateway
			runTool: toolUse
			forUserRequest: 'Build a widget for my saved city.'.
		self assert: ((result at: 'content') beginsWith: 'ERROR: fact write rejected').
		self assert: fact body equals: 'Lisbon'.
		self assert: AgentCanvas current facts size equals: 1 ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolRejectsParenthesizedFactLiteralBeforeEvaluation [
	| fact toolUse result |
	[
		AgentCanvas reset.
		fact := AgentFact key: #city body: 'Lisbon'.
		toolUse := {
			'id' -> 'tu_fact_parenthesized_reject'.
			'input' -> ({ 'code' -> 'AgentFact key: #city body: (''Porto'')' } asDictionary) }
			asDictionary.
		result := gateway
			runTool: toolUse
			forUserRequest: 'Use Porto when configuring the widget.'.
		self assert: ((result at: 'content') beginsWith: 'ERROR: fact write rejected').
		self assert: fact body equals: 'Lisbon'.
		self assert: AgentCanvas current facts size equals: 1 ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolParsesEscapedAndMultipleFactLiteralsIndependently [
	| toolUse result facts |
	[
		AgentCanvas reset.
		toolUse := {
			'id' -> 'tu_fact_multiple_allow'.
			'input' -> ({ 'code' -> 'AgentFact key: #nickname body: ''O''''Brien''. AgentFact body: ''I prefer tea''' } asDictionary) }
			asDictionary.
		result := gateway
			runTool: toolUse
			forUserRequest: 'Remember that my nickname is O''Brien and I prefer tea.'.
		self assert: ((result at: 'content') beginsWith: 'RESULT:').
		facts := AgentCanvas current facts.
		self assert: (AgentCanvas current factWithKey: #nickname) body equals: 'O''Brien'.
		self assert: facts size equals: 2 ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testRunToolRejectsEveryFactWriteWhenOneLiteralIsUnauthorized [
	| existing toolUse result |
	[
		AgentCanvas reset.
		existing := AgentFact key: #city body: 'Lisbon'.
		toolUse := {
			'id' -> 'tu_fact_multiple_reject'.
			'input' -> ({ 'code' -> 'AgentFact key: #city body: ''Porto''. AgentFact key: #timezone body: ''UTC''' } asDictionary) }
			asDictionary.
		result := gateway
			runTool: toolUse
			forUserRequest: 'I moved to Porto. Update my city.'.
		self assert: ((result at: 'content') beginsWith: 'ERROR: fact write rejected').
		self assert: existing body equals: 'Lisbon'.
		self assert: (AgentCanvas current factWithKey: #timezone) isNil.
		self assert: AgentCanvas current facts size equals: 1 ]
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
AgentGatewayTest >> testSystemPromptForbidsEmojiAndPictographs [
	| prompt |
	prompt := gateway systemPrompt.
	self assert: (prompt includesSubstring: 'Do not put emoji or Unicode pictographs in text strings').
	self assert: (prompt includesSubstring: 'abort the canvas render').
	self deny: (prompt includesSubstring: '''☀ '' , city').
	self deny: (prompt includesSubstring: 'AgentIcon').
	self deny: (prompt includesSubstring: 'ToMaterialDesignIconProvider')
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
AgentGatewayTest >> testScriptedTransportExercisesKnowledgeToolLoop [
	| transport result secondRequest toolResult knowledgeResult |
	[
		AgentCanvas reset.
		AgentFact key: #city body: 'Tokyo'.
		transport := AgentGatewayFakeTransport responses: {
			{ 'content' -> {
				{ 'type' -> 'tool_use'.
					'id' -> 'tu_knowledge_loop'.
					'name' -> 'inspect_knowledge'.
					'input' -> ({ 'action' -> 'get_fact'. 'key' -> 'city' } asDictionary) }
					asDictionary
				} } asDictionary.
			{ 'content' -> {
				{ 'type' -> 'text'. 'text' -> 'The saved city is Tokyo.' } asDictionary
				} } asDictionary }.
		gateway
			transport: transport;
			apiKey: 'test-key';
			maxRounds: 10.
		result := gateway run: 'What city is saved?'.
		self assert: result equals: 'The saved city is Tokyo.'.
		self assert: transport payloads size equals: 2.
		secondRequest := transport payloads second.
		toolResult := ((secondRequest at: 'messages') last at: 'content') first.
		self assert: (toolResult at: 'tool_use_id') equals: 'tu_knowledge_loop'.
		knowledgeResult := STONJSON fromString: (toolResult at: 'content').
		self assert: (knowledgeResult at: 'schema') equals: 'agent-knowledge/v1'.
		self assert: (knowledgeResult at: 'trust') equals: 'untrusted-data'.
		self assert: (knowledgeResult at: 'found').
		self assert: (((knowledgeResult at: 'items') first at: 'content')) equals: 'Tokyo' ]
		ensure: [ AgentCanvas reset ]
]

{ #category : 'tests' }
AgentGatewayTest >> testProviderEvaluationMetricsRecordUsageAndRepairAttempts [
	| transport report usage |
	transport := AgentGatewayFakeTransport responses: {
		{ 'content' -> {
			{ 'type' -> 'tool_use'.
				'id' -> 'tu_bad'.
				'name' -> 'evaluate_smalltalk'.
				'input' -> ({ 'code' -> '1 zork' } asDictionary) } asDictionary
			}. 'usage' -> ({ 'input_tokens' -> 10. 'output_tokens' -> 2 } asDictionary) }
			asDictionary.
		{ 'content' -> {
			{ 'type' -> 'tool_use'.
				'id' -> 'tu_repair'.
				'name' -> 'evaluate_smalltalk'.
				'input' -> ({ 'code' -> '3 + 4' } asDictionary) } asDictionary
			}. 'usage' -> ({ 'input_tokens' -> 12. 'output_tokens' -> 3 } asDictionary) }
			asDictionary.
		{ 'content' -> {
			{ 'type' -> 'text'. 'text' -> 'seven' } asDictionary
			}. 'usage' -> ({ 'input_tokens' -> 8. 'output_tokens' -> 4 } asDictionary) }
			asDictionary }.
	gateway
		transport: transport;
		apiKey: 'test-key';
		maxRounds: 4.
	gateway run: 'calculate three plus four'.
	usage := gateway usageTotals.
	self assert: gateway requestCount equals: 3.
	self assert: gateway repairAttempts equals: 1.
	self assert: (usage at: 'input_tokens') equals: 30.
	self assert: (usage at: 'output_tokens') equals: 9.
	report := AgentEvaluation
		reportNamed: 'metrics-test'
		gateways: { gateway }
		startedAt: 100
		endedAt: 145
		passed: true
		details: ({ 'check' -> true } asDictionary).
	self assert: (report at: 'outcome') equals: 'passed'.
	self assert: (report at: 'rounds') equals: 3.
	self assert: (report at: 'repairs') equals: 1.
	self assert: ((report at: 'usage') at: 'input_tokens') equals: 30.
	self assert: (report at: 'latency_ms') equals: 45
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
