"Paid comparison of tool-first fact retrieval with the former always-serialized
shape. The baseline gateway exists only in this disposable image: it appends
every fixture fact to every prompt. Both runs must answer the same natural
reference; token and serialized-payload differences are recorded as evidence,
not asserted to favor either design for every fact-set size."
| toolFirstGateway baselineGateway baselineClass gateways canvas filler
toolFirstPrompt baselinePrompt baselineFactAppendixCharacters
baselineSerializesFacts toolFirstAnswer baselineAnswer toolFirstUsedGetFact
toolFirstAnswered baselineAnswered toolFirstMetrics baselineMetrics
toolFirstInputTokens baselineInputTokens inputTokenDelta payloadCharacterDelta
fixtureFactCount passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
toolFirstGateway := AgentGateway new.
baselineGateway := nil.
gateways := OrderedCollection with: toolFirstGateway.
toolFirstAnswer := ''.
baselineAnswer := ''.
toolFirstUsedGetFact := false.
toolFirstAnswered := false.
baselineAnswered := false.
baselineFactAppendixCharacters := 0.
baselineSerializesFacts := false.
toolFirstMetrics := Dictionary new.
baselineMetrics := Dictionary new.
toolFirstInputTokens := 0.
baselineInputTokens := 0.
inputTokenDelta := 0.
payloadCharacterDelta := 0.
fixtureFactCount := 0.
[
	AgentCanvas reset.
	canvas := AgentCanvas current.
	AgentFact key: #city body: 'Ushuaia'.
	1 to: 12 do: [ :index |
		filler := 'baseline fixture ' , index printString , ': '
			, (String new: 600 withAll: $x).
		AgentFact key: ('baselineFiller' , index printString) asSymbol body: filler ].
	fixtureFactCount := canvas facts size.
	baselineClass := AgentGateway << #AS04AlwaysSerializedFactsBaselineGateway
		slots: #();
		package: 'AgentSmalltalk-Evaluation';
		install.
	baselineClass compile: 'systemPrompt
	^ super systemPrompt , String cr , String cr
		, (AgentCanvas current facts inject: ''## Known facts (always-serialized baseline)'' into: [ :text :fact |
			text , String cr , fact key asString , '': '' , fact body ])'.
	baselineGateway := baselineClass new.
	gateways add: baselineGateway.
	toolFirstPrompt := toolFirstGateway systemPrompt.
	baselinePrompt := baselineGateway systemPrompt.
	baselineFactAppendixCharacters := baselinePrompt size - toolFirstPrompt size.
	baselineSerializesFacts := (baselinePrompt includesSubstring: 'Ushuaia')
		and: [ baselinePrompt includesSubstring: 'baseline fixture 12' ].

	Stdio stdout nextPutAll: '--- tool-first retrieval ---'; lf.
	toolFirstAnswer := [ toolFirstGateway run:
		'What city do I live in? Reply with just the city.' ]
		on: Error do: [ :error | failure := error messageText. '' ].
	Stdio stdout nextPutAll: toolFirstAnswer; lf.
	toolFirstUsedGetFact := toolFirstGateway log anySatisfy: [ :line |
		(line beginsWith: 'KNOWLEDGE? ')
			and: [ line includesSubstring: 'get_fact' ] ].
	toolFirstAnswered := toolFirstAnswer asLowercase includesSubstring: 'ushuaia'.

	Stdio stdout nextPutAll: '--- always-serialized baseline ---'; lf.
	baselineAnswer := [ baselineGateway run:
		'What city do I live in? Reply with just the city.' ]
		on: Error do: [ :error | failure := error messageText. '' ].
	Stdio stdout nextPutAll: baselineAnswer; lf.
	baselineAnswered := baselineAnswer asLowercase includesSubstring: 'ushuaia'.

	toolFirstMetrics := toolFirstGateway requestMetrics.
	baselineMetrics := baselineGateway requestMetrics.
	toolFirstInputTokens := (toolFirstMetrics at: 'usage') at: 'input_tokens'.
	baselineInputTokens := (baselineMetrics at: 'usage') at: 'input_tokens'.
	inputTokenDelta := baselineInputTokens - toolFirstInputTokens.
	payloadCharacterDelta := (((baselineMetrics at: 'payload') at: 'total_characters')
		- ((toolFirstMetrics at: 'payload') at: 'total_characters')).
	passed := failure isNil
		and: [ baselineFactAppendixCharacters > 0
		and: [ baselineSerializesFacts
		and: [ toolFirstUsedGetFact
		and: [ toolFirstAnswered and: [ baselineAnswered ] ] ] ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'fact-baseline'
			gateways: gateways
			startedAt: started
			passed: passed
			details: {
				'fixture_fact_count' -> fixtureFactCount.
				'baseline_serializes_fact_values' -> baselineSerializesFacts.
				'baseline_fact_appendix_characters' -> baselineFactAppendixCharacters.
				'tool_first_used_get_fact' -> toolFirstUsedGetFact.
				'tool_first_answered' -> toolFirstAnswered.
				'baseline_answered' -> baselineAnswered.
				'tool_first' -> toolFirstMetrics.
				'baseline' -> baselineMetrics.
				'input_token_delta_baseline_minus_tool_first' -> inputTokenDelta.
				'payload_character_delta_baseline_minus_tool_first' -> payloadCharacterDelta.
				'failure' -> (failure ifNil: [ '' ]) } asDictionary.
		AgentCanvas reset ].

Stdio stdout nextPutAll: '=== COMPARISON ==='; lf.
Stdio stdout nextPutAll: 'fixture facts: ' , fixtureFactCount printString; lf.
Stdio stdout nextPutAll: 'baseline fact appendix chars: '
	, baselineFactAppendixCharacters printString; lf.
Stdio stdout nextPutAll: 'tool-first input tokens: ' , toolFirstInputTokens printString; lf.
Stdio stdout nextPutAll: 'baseline input tokens: ' , baselineInputTokens printString; lf.
Stdio stdout nextPutAll: 'input token delta (baseline - tool-first): '
	, inputTokenDelta printString; lf.
Stdio stdout nextPutAll: 'payload char delta (baseline - tool-first): '
	, payloadCharacterDelta printString; lf.
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'FACT BASELINE COMPARISON OK' ]
	ifFalse: [ 'FACT BASELINE COMPARISON FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
