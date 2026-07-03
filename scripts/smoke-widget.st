"Headless acceptance probe: ask the gateway for a counter widget, dump the
loop transcript, and report what widget classes now exist. Does not save the
image, so every run is a cold run."
| gateway answer |
gateway := AgentGateway new.
answer := [ gateway run: 'make me a counter widget with plus and minus buttons' ]
	on: Error
	do: [ :e | 'GATEWAY FAILED: ' , e messageText ].
Stdio stdout nextPutAll: '=== ANSWER ==='; lf.
Stdio stdout nextPutAll: answer; lf; lf.
Stdio stdout nextPutAll: '=== LOOP TRANSCRIPT ==='; lf.
gateway log do: [ :line |
	Stdio stdout nextPutAll: line; lf.
	Stdio stdout nextPutAll: '---'; lf ].
Stdio stdout nextPutAll: '=== WIDGET CLASSES ==='; lf.
AgentWidget subclasses do: [ :cls |
	Stdio stdout nextPutAll: cls name , ' -> ' , cls selectors asSortedCollection asArray printString; lf.
	Stdio stdout nextPutAll: '   canvas: ' , AgentCanvas current contextDescription; lf ].
Smalltalk exitSuccess
