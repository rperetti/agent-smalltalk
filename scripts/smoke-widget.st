"Paid cold-generation evaluation for a counter widget. It verifies the real
instance can increment, not merely that the model returned a plausible answer."
| gateway answer widgets counter passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
widgets := #().
counter := nil.
gateway := AgentGateway new.
[
	answer := [ gateway run: 'make me a counter widget with plus and minus buttons' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: '=== ANSWER ==='; lf; nextPutAll: answer; lf; lf.
	Stdio stdout nextPutAll: '=== LOOP TRANSCRIPT ==='; lf.
	gateway log do: [ :line |
		Stdio stdout nextPutAll: line; lf;
			nextPutAll: '---'; lf ].
	widgets := AgentCanvas current contextWidgets.
	counter := widgets detect: [ :widget | widget respondsTo: #increment ] ifNone: [ nil ].
	counter ifNotNil: [ counter increment ].
	passed := failure isNil
		and: [ counter notNil
		and: [ counter describe includesSubstring: '1' ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'widget'
			gateways: { gateway }
			startedAt: started
			passed: passed
			details: {
				'widget_count' -> widgets size.
				'counter_created' -> counter notNil.
				'increment_works' -> (counter notNil and: [ counter describe includesSubstring: '1' ]).
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: '=== WIDGETS ==='; lf.
widgets do: [ :widget |
	Stdio stdout nextPutAll: widget class name , ': ' , widget describe; lf ].
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'WIDGET SMOKE OK' ]
	ifFalse: [ 'WIDGET SMOKE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
