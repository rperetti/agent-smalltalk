"Paid evaluation for live modification. State must survive: three initial
increments plus one revised increment equals thirteen on the same instance."
| gateways gateway answer widget passed failure started sameInstance |
started := Time millisecondClockValue.
passed := false.
failure := nil.
widget := nil.
sameInstance := false.
gateways := OrderedCollection new.
[
	Stdio stdout nextPutAll: '--- A: create ---'; lf.
	gateway := AgentGateway new.
	gateways add: gateway.
	answer := [ gateway run: 'make me a counter widget with plus and minus buttons' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: answer; lf.
	widget := AgentCanvas current contextWidgets
		detect: [ :candidate | candidate respondsTo: #increment ]
		ifNone: [ nil ].
	widget ifNotNil: [ 3 timesRepeat: [ widget increment ] ].
	Stdio stdout nextPutAll: 'after 3 clicks: '
		, (widget ifNil: [ 'NO WIDGET CREATED' ] ifNotNil: [ widget describe ]); lf.
	Stdio stdout nextPutAll: '--- B: modify live ---'; lf.
	gateway := AgentGateway new.
	gateways add: gateway.
	answer := [ gateway run: 'change the counter so it counts by 10 instead of 1' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: answer; lf.
	widget ifNotNil: [
		widget increment.
		sameInstance := AgentCanvas current contextWidgets includes: widget ].
	passed := failure isNil
		and: [ sameInstance
		and: [ widget notNil and: [ widget describe includesSubstring: '13' ] ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'modify'
			gateways: gateways
			startedAt: started
			passed: passed
			details: {
				'same_instance' -> sameInstance.
				'final_description' -> (widget ifNil: [ '' ] ifNotNil: [ widget describe ]).
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: (passed
	ifTrue: [ 'LIVE MODIFICATION OK' ]
	ifFalse: [ 'LIVE MODIFICATION FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
