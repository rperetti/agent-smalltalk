"Paid evaluation for selection-scoped context and live references. Three
counters (3, 5, 7) become a total; changing Selection1 to 13 must yield 25."
| canvas counters total prompt gateway answer cls before promptScoped liveReferences passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
total := nil.
promptScoped := false.
liveReferences := false.
gateway := AgentGateway new.
AgentCanvas reset.
[
	cls := AgentWidget defineNamed: #AcceptCounter slots: #(count).
	cls compile: 'count ^ count ifNil: [0]'.
	cls compile: 'count: n count := n'.
	cls compile: 'describe ^ ''a counter at '' , self count printString'.
	canvas := AgentCanvas current.
	counters := (1 to: 3) collect: [ :i |
		| counter |
		counter := cls new.
		counter count: i * 2 + 1.
		canvas addWidget: counter.
		counter ].
	canvas selectWidgets: counters.
	prompt := AgentGateway new systemPrompt.
	promptScoped := (prompt includesSubstring: 'Selected widgets')
		and: [ prompt includesSubstring: cls name ].
	Stdio stdout nextPutAll: 'scoped prompt contains selected counters: '
		, promptScoped printString; lf.
	before := canvas toolWidgets asIdentitySet.
	answer := [ gateway run:
		'make a widget that shows the sum of these selected counters, with a Refresh button' ]
		on: Error do: [ :e | failure := e messageText. '' ].
	Stdio stdout nextPutAll: '=== ANSWER ==='; lf; nextPutAll: answer; lf.
	total := canvas toolWidgets
		detect: [ :widget | (before includes: widget) not ]
		ifNone: [ nil ].
	total ifNotNil: [
		(Smalltalk globals at: #Selection1) count: 13.
		(total respondsTo: #refresh) ifTrue: [ total refresh ].
		liveReferences := (total respondsTo: #refresh)
			and: [ total describe includesSubstring: '25' ] ].
	passed := failure isNil and: [ promptScoped and: [ liveReferences ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'selection'
			gateways: { gateway }
			startedAt: started
			passed: passed
			details: {
				'prompt_scoped' -> promptScoped.
				'total_created' -> total notNil.
				'live_references' -> liveReferences.
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: (passed
	ifTrue: [ 'LIVE REFERENCES OK' ]
	ifFalse: [ 'SELECTION SMOKE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
