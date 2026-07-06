"Headless acceptance for text-input widgets (the category that used to exhaust
the round budget): the model should reach for ToTextField from the base prompt
instead of exploring the image."
| gateway answer |
gateway := AgentGateway new.
answer := [ gateway run: 'make a widget where I type some text, press a Reverse button, and see the text reversed in a label' ]
	on: Error
	do: [ :e | 'GATEWAY FAILED: ' , e messageText ].
Stdio stdout nextPutAll: '=== ANSWER ==='; lf.
Stdio stdout nextPutAll: answer; lf.
Stdio stdout nextPutAll: '=== ROUNDS USED ==='; lf.
Stdio stdout nextPutAll: (gateway log count: [ :l | l beginsWith: '[status]' ]) printString; lf.
Stdio stdout nextPutAll: '=== TOOL CALLS ==='; lf.
gateway log do: [ :line |
	((line beginsWith: '>>> ') or: [ line beginsWith: '??? ' ]) ifTrue: [
		Stdio stdout nextPutAll: (line copyFrom: 1 to: (line size min: 90)); lf ] ].
Stdio stdout nextPutAll: '=== WIDGETS ==='; lf.
AgentCanvas current widgets do: [ :w |
	Stdio stdout nextPutAll: w class name , ': ' , w describe; lf ].
Smalltalk exitSuccess
