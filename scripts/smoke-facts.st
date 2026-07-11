"Paid evaluation for canvas knowledge: explicit and implicit fact capture,
same-key replacement, and fact-dependent widget creation."
| gateways run city name facts cityUpdated nameCaptured widgetsCreated passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
gateways := OrderedCollection new.
city := nil.
name := nil.
facts := #().
cityUpdated := false.
nameCaptured := false.
widgetsCreated := false.
AgentCanvas reset.
run := [ :label :request |
	| gateway answer |
	Stdio stdout nextPutAll: '--- ' , label , ': ' , request; lf.
	gateway := AgentGateway new.
	gateways add: gateway.
	answer := [ gateway run: request ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: answer; lf ].
[
	run value: 'A' value: 'remember that I live in Lisbon'.
	run value: 'B' value: 'make me a widget showing the current time in my city'.
	run value: 'C' value: 'actually I moved to Madrid'.
	run value: 'D' value: 'make a greeting widget. by the way, my name is Sam'.
	facts := AgentCanvas current facts.
	city := AgentCanvas current factWithKey: #city.
	name := AgentCanvas current factWithKey: #name.
	cityUpdated := city notNil and: [ city body trimBoth = 'Madrid' ].
	nameCaptured := name notNil and: [ name body trimBoth = 'Sam' ].
	widgetsCreated := AgentCanvas current toolWidgets size >= 2.
	passed := failure isNil
		and: [ cityUpdated
		and: [ nameCaptured
		and: [ widgetsCreated
		and: [ facts noneSatisfy: [ :fact |
			fact body asLowercase includesSubstring: 'lisbon' ] ] ] ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'facts'
			gateways: gateways
			startedAt: started
			passed: passed
			details: {
				'fact_count' -> facts size.
				'city_updated' -> cityUpdated.
				'name_captured' -> nameCaptured.
				'widgets_created' -> widgetsCreated.
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: '=== CHECKS ==='; lf.
Stdio stdout nextPutAll: 'fact count: ' , facts size printString; lf.
Stdio stdout nextPutAll: 'city updated: ' , cityUpdated printString; lf.
Stdio stdout nextPutAll: 'implicit name captured: ' , nameCaptured printString; lf.
Stdio stdout nextPutAll: 'tool widgets: ' , AgentCanvas current toolWidgets size printString; lf.
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'FACTS SMOKE OK' ]
	ifFalse: [ 'FACTS SMOKE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
