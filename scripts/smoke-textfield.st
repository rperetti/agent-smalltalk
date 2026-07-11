"Paid evaluation for a text-input widget. The gate checks the generated
implementation uses the documented input control and contains reverse logic."
| gateway answer widgets textWidget hasInput hasReverse passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
widgets := #().
textWidget := nil.
hasInput := false.
hasReverse := false.
gateway := AgentGateway new.
[
	answer := [ gateway run:
		'make a widget where I type some text, press a Reverse button, and see the text reversed in a label' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: '=== ANSWER ==='; lf; nextPutAll: answer; lf.
	widgets := AgentCanvas current contextWidgets.
	textWidget := widgets detect: [ :widget |
		widget class methods anySatisfy: [ :method |
			method sourceCode includesSubstring: 'ToTextField' ] ] ifNone: [ nil ].
	hasInput := textWidget notNil.
	hasReverse := textWidget notNil and: [ textWidget class methods anySatisfy: [ :method |
		method sourceCode asLowercase includesSubstring: 'reverse' ] ].
	passed := failure isNil and: [ hasInput and: [ hasReverse ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'textfield'
			gateways: { gateway }
			startedAt: started
			passed: passed
			details: {
				'widget_count' -> widgets size.
				'uses_text_field' -> hasInput.
				'has_reverse_logic' -> hasReverse.
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: '=== ROUNDS USED ==='; lf.
Stdio stdout nextPutAll: gateway requestCount printString; lf.
Stdio stdout nextPutAll: '=== TOOL CALLS ==='; lf.
gateway log do: [ :line |
	((line beginsWith: '>>> ') or: [ line beginsWith: '??? ' ]) ifTrue: [
		Stdio stdout nextPutAll: (line copyFrom: 1 to: (line size min: 90)); lf ] ].
Stdio stdout nextPutAll: '=== WIDGETS ==='; lf.
widgets do: [ :widget |
	Stdio stdout nextPutAll: widget class name , ': ' , widget describe; lf ].
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'TEXTFIELD SMOKE OK' ]
	ifFalse: [ 'TEXTFIELD SMOKE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
