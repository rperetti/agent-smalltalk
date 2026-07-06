"Headless acceptance for phase 2 (knowledge on the canvas):
A) explicit remember -> sticky appears
B) fact-dependent widget built without asking
C) restated fact updates the same sticky (no duplicate)
D) implicit capture: fact stated in passing while asking for a widget"
| report |
report := [ :label :request |
	| answer |
	Stdio stdout nextPutAll: '--- ' , label , ': ' , request; lf.
	answer := [ AgentGateway ask: request ]
		on: Error do: [ :e | 'FAILED: ' , e messageText ].
	Stdio stdout nextPutAll: answer; lf.
	Stdio stdout nextPutAll: 'facts now: '.
	AgentCanvas current facts
		do: [ :f | Stdio stdout nextPutAll: '(' , f describe , ') ' ].
	Stdio stdout lf; lf ].

report value: 'A' value: 'remember that I live in Lisbon'.
report value: 'B' value: 'make me a widget showing the current time in my city'.
report value: 'C' value: 'actually I moved to Madrid'.
report value: 'D' value: 'make a greeting widget. by the way, my name is Sam'.

Stdio stdout nextPutAll: '=== CHECKS ==='; lf.
Stdio stdout nextPutAll: 'fact count (expect 2): ' , AgentCanvas current facts size printString; lf.
Stdio stdout nextPutAll: 'city updated (expect true): '
	, ((AgentCanvas current facts anySatisfy: [ :f | f body asLowercase includesSubstring: 'madrid' ]) and: [
		AgentCanvas current facts noneSatisfy: [ :f | f body asLowercase includesSubstring: 'lisbon' ] ]) printString; lf.
Stdio stdout nextPutAll: 'tool widgets (expect 2): ' , AgentCanvas current toolWidgets size printString; lf.
AgentCanvas current toolWidgets do: [ :w |
	Stdio stdout nextPutAll: '  ' , w class name , ': ' , w describe; lf ].
Smalltalk exitSuccess
