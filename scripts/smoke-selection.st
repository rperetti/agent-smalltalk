"Headless acceptance for phase 3: selection-scoped context + live references.
Creates three counters (3,5,7), selects them, asks for a sum widget, then
mutates a counter through Selection1 and refreshes the total: expect 25.
Does NOT save the image."
| canvas counters total prompt answer cls before |
cls := AgentWidget defineNamed: #AcceptCounter slots: #(count).
cls compile: 'count ^ count ifNil: [0]'.
cls compile: 'count: n count := n'.
cls compile: 'describe ^ ''a counter at '' , self count printString'.
canvas := AgentCanvas current.
counters := (1 to: 3) collect: [ :i |
	| c |
	c := cls new.
	c count: i * 2 + 1.
	canvas addWidget: c.
	c ].
canvas selectWidgets: counters.
prompt := AgentGateway new systemPrompt.
Stdio stdout nextPutAll: 'scoped prompt ok (selected in, others out): '
	, ((prompt includesSubstring: 'Selected widgets')
		and: [ (prompt includesSubstring: 'WeatherWidget') not ]) printString; lf.
before := canvas toolWidgets asIdentitySet.
answer := [ AgentGateway ask: 'make a widget that shows the sum of these selected counters, with a Refresh button' ]
	on: Error do: [ :e | 'FAILED: ' , e messageText ].
Stdio stdout nextPutAll: '=== ANSWER ==='; lf; nextPutAll: answer; lf.
total := canvas toolWidgets
	detect: [ :w | (before includes: w) not ]
	ifNone: [ nil ].
total
	ifNil: [ Stdio stdout nextPutAll: 'NO TOTAL WIDGET CREATED'; lf ]
	ifNotNil: [
		Stdio stdout nextPutAll: 'total widget: ' , total class name , ' -- ' , total describe; lf.
		(Smalltalk globals at: #Selection1) count: 13.
		(total respondsTo: #refresh)
			ifTrue: [
				total refresh.
				Stdio stdout nextPutAll: 'after Selection1 -> 13 and refresh: ' , total describe; lf.
				Stdio stdout nextPutAll: ((total describe includesSubstring: '25')
					ifTrue: [ 'LIVE REFERENCES OK' ]
					ifFalse: [ 'UNEXPECTED SUM' ]); lf ]
			ifFalse: [ Stdio stdout nextPutAll: 'no #refresh; selectors: ' , total class selectors printString; lf ] ].
Smalltalk exitSuccess
