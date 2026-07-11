"Paid evaluation for canvas reactions. It checks a fact-backed widget follows a
city change, then a generated total follows a counter announcement unaided."
| canvas gateways gateway answer counters cls beforeDescribes changed factFollowed totalFollowed passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
factFollowed := false.
totalFollowed := false.
gateways := OrderedCollection new.
AgentCanvas reset.
[
	canvas := AgentCanvas current.
	AgentFact key: #city body: 'Tokyo'.
	Stdio stdout nextPutAll: '--- A: reactive city widget ---'; lf.
	gateway := AgentGateway new.
	gateways add: gateway.
	answer := [ gateway run:
		'make sure there is a clock widget showing the current time in my city, staying correct if my city ever changes' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: answer; lf.
	AgentFact key: #city body: 'Reykjavik'.
	factFollowed := canvas toolWidgets anySatisfy: [ :widget |
		widget describe asLowercase includesSubstring: 'reykjavik' ].
	Stdio stdout nextPutAll: 'reactive fact: ' , factFollowed printString; lf.

	Stdio stdout nextPutAll: '--- B: live total ---'; lf.
	cls := AgentWidget defineNamed: #ReactCounter slots: #(count).
	cls compile: 'count ^ count ifNil: [0]'.
	cls compile: 'bump count := self count + 1. self announceChanged'.
	cls compile: 'describe ^ ''a counter at '' , self count printString'.
	counters := (1 to: 3) collect: [ :i |
		| counter |
		counter := cls new.
		i timesRepeat: [ counter bump ].
		canvas addWidget: counter.
		counter ].
	canvas selectWidgets: counters.
	gateway := AgentGateway new.
	gateways add: gateway.
	answer := [ gateway run:
		'make a live total of these selected counters - it must update by itself when any counter changes, no refresh button' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: answer; lf.
	beforeDescribes := (canvas toolWidgets reject: [ :widget | widget isKindOf: cls ])
		collect: [ :widget | widget -> widget describe ].
	(Smalltalk globals at: #Selection1) bump.
	changed := beforeDescribes select: [ :association |
		association key describe ~= association value ].
	totalFollowed := changed notEmpty.
	changed do: [ :association |
		Stdio stdout nextPutAll: 'changed by itself: ' , association key describe; lf ].
	passed := failure isNil and: [ factFollowed and: [ totalFollowed ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'reactive'
			gateways: gateways
			startedAt: started
			passed: passed
			details: {
				'fact_followed' -> factFollowed.
				'total_followed' -> totalFollowed.
				'changed_widgets' -> (changed ifNil: [ 0 ] ifNotNil: [ changed size ]).
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: (passed
	ifTrue: [ 'REACTIVE WIDGETS OK' ]
	ifFalse: [ 'REACTIVE SMOKE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
