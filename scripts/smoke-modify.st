"Headless acceptance for the live-modification flow (demo step 6):
create a counter, run it up to 3, then ask the agent to change the running
widget's behavior. State must survive: 3 + one new-style increment = 13."
| answer widget |
Stdio stdout nextPutAll: '--- A: create ---'; lf.
answer := [ AgentGateway ask: 'make me a counter widget with plus and minus buttons' ]
	on: Error do: [ :e | 'FAILED: ' , e messageText ].
Stdio stdout nextPutAll: answer; lf.
widget := AgentCanvas current widgets
	ifEmpty: [ Stdio stdout nextPutAll: 'NO WIDGET CREATED'; lf. Smalltalk exitFailure ]
	ifNotEmpty: [ :ws | ws first ].
(widget respondsTo: #increment)
	ifFalse: [ Stdio stdout nextPutAll: 'no #increment; selectors: ' , widget class selectors printString; lf.
		Smalltalk exitFailure ].
3 timesRepeat: [ widget increment ].
Stdio stdout nextPutAll: 'after 3 clicks: ' , widget describe; lf.
Stdio stdout nextPutAll: '--- B: modify live ---'; lf.
answer := [ AgentGateway ask: 'change the counter so it counts by 10 instead of 1' ]
	on: Error do: [ :e | 'FAILED: ' , e messageText ].
Stdio stdout nextPutAll: answer; lf.
widget increment.
Stdio stdout nextPutAll: 'same instance after one more click: ' , widget describe; lf.
Stdio stdout nextPutAll: ((widget describe includesSubstring: '13')
	ifTrue: [ 'LIVE MODIFICATION OK' ]
	ifFalse: [ 'UNEXPECTED STATE' ]); lf.
Smalltalk exitSuccess
