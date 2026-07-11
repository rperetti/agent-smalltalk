"Paid evaluation for reusable tools: create a weather tool, expose it in the
next request's capability context, and reuse rather than duplicate it."
| gateways gateway answer weatherTools before promptHadCapabilities passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
gateways := OrderedCollection new.
weatherTools := #().
before := 0.
promptHadCapabilities := false.
AgentCanvas reset.
[
	Stdio stdout nextPutAll: '--- A: build a tool ---'; lf.
	gateway := AgentGateway new.
	gateways add: gateway.
	answer := [ gateway run:
		'make me a weather widget for Tokyo showing the current temperature (use a reusable tool for the fetch)' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: answer; lf.
	weatherTools := AgentTool tools select: [ :tool |
		(tool name asLowercase includesSubstring: 'weather')
			or: [ (tool purpose ifNil: [ '' ]) asLowercase includesSubstring: 'weather' ] ].
	before := weatherTools size.
	promptHadCapabilities := (AgentGateway new systemPrompt includesSubstring: 'Capabilities you''ve built')
		and: [ weatherTools notEmpty and: [
			AgentGateway new systemPrompt includesSubstring: weatherTools anyOne name ] ].
	Stdio stdout nextPutAll: 'capabilities section lists the weather tool: '
		, promptHadCapabilities printString; lf.
	Stdio stdout nextPutAll: '--- B: reuse it ---'; lf.
	gateway := AgentGateway new.
	gateways add: gateway.
	answer := [ gateway run: 'make a widget comparing the current temperature in Tokyo and London' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: answer; lf.
	weatherTools := AgentTool tools select: [ :tool |
		(tool name asLowercase includesSubstring: 'weather')
			or: [ (tool purpose ifNil: [ '' ]) asLowercase includesSubstring: 'weather' ] ].
	passed := failure isNil
		and: [ promptHadCapabilities
		and: [ before >= 1 and: [ weatherTools size = before ] ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'tools'
			gateways: gateways
			startedAt: started
			passed: passed
			details: {
				'weather_tools_before_second_request' -> before.
				'weather_tools_after_second_request' -> weatherTools size.
				'capability_context_lists_tool' -> promptHadCapabilities.
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: 'weather tools after B: ' , weatherTools size printString; lf.
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'REUSE OK (no duplicate weather tool)' ]
	ifFalse: [ 'TOOLS SMOKE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
