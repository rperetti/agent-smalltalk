"Paid evaluation for the base prompt's operational contract. It proves that the
model uses a read-only tool without evaluating code, then creates and exercises
a reusable tool through distinct definition, compilation, and test calls."
| searchGateway buildGateway gateways searchAnswer buildAnswer searchUsed
searchAvoidedEvaluation tool definitionLine compileLine separateCalls toolWorks
passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
searchGateway := AgentGateway new.
buildGateway := AgentGateway new.
gateways := { searchGateway. buildGateway }.
searchAnswer := ''.
buildAnswer := ''.
searchUsed := false.
searchAvoidedEvaluation := false.
tool := nil.
definitionLine := nil.
compileLine := nil.
separateCalls := false.
toolWorks := false.
[
	AgentCanvas reset.
	Stdio stdout nextPutAll: '--- read-only image search ---'; lf.
	searchAnswer := [ searchGateway run:
		'Use search_image, not evaluate_smalltalk, to find the implementation of AgentWidget>>#describe. Reply only whether the method exists.' ]
		on: Error do: [ :error | failure := error messageText. '' ].
	Stdio stdout nextPutAll: searchAnswer; lf.
	searchUsed := searchGateway log anySatisfy: [ :line |
		line beginsWith: '??? ' ].
	searchAvoidedEvaluation := (searchGateway log anySatisfy: [ :line |
		line beginsWith: '>>> ' ]) not.

	Stdio stdout nextPutAll: '--- separate reusable-tool calls ---'; lf.
	buildAnswer := [ buildGateway run:
		'Create one reusable AgentTool named CelsiusFahrenheitService. It needs one class-side method, fahrenheitForCelsius:, which converts 100 to 212. Define the class in one evaluate_smalltalk call by itself, wait for its RESULT, compile the method in a later call, then test the method in another call. Do not create a widget.' ]
		on: Error do: [ :error | failure := error messageText. '' ].
	Stdio stdout nextPutAll: buildAnswer; lf.
	tool := AgentTool tools
		detect: [ :each | each name = #CelsiusFahrenheitService ]
		ifNone: [ nil ].
	definitionLine := buildGateway log
		detect: [ :line | line includesSubstring: 'AgentTool defineNamed: #CelsiusFahrenheitService' ]
		ifNone: [ nil ].
	compileLine := buildGateway log
		detect: [ :line | line includesSubstring: 'CelsiusFahrenheitService class compile:' ]
		ifNone: [ nil ].
	separateCalls := definitionLine notNil
		and: [ compileLine notNil and: [ definitionLine ~~ compileLine ] ].
	toolWorks := tool notNil and: [ (tool fahrenheitForCelsius: 100) = 212 ].
	passed := failure isNil
		and: [ searchUsed
		and: [ searchAvoidedEvaluation
		and: [ separateCalls and: [ toolWorks ] ] ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'prompt-contract'
			gateways: gateways
			startedAt: started
			passed: passed
			details: {
				'search_used' -> searchUsed.
				'search_avoided_evaluation' -> searchAvoidedEvaluation.
				'definition_and_compilation_are_separate_calls' -> separateCalls.
				'generated_tool_works' -> toolWorks.
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: '=== CHECKS ==='; lf.
Stdio stdout nextPutAll: 'read-only search used: ' , searchUsed printString; lf.
Stdio stdout nextPutAll: 'read-only search avoided evaluation: '
	, searchAvoidedEvaluation printString; lf.
Stdio stdout nextPutAll: 'tool definition and compilation separated: '
	, separateCalls printString; lf.
Stdio stdout nextPutAll: 'generated tool works: ' , toolWorks printString; lf.
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'PROMPT CONTRACT SMOKE OK' ]
	ifFalse: [ 'PROMPT CONTRACT SMOKE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
