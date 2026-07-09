"Headless acceptance for self-evolving tools. Does NOT save.
A) a weather request builds a reusable weather TOOL (+ widget)
B) a second weather request REUSES the tool instead of rebuilding the fetch:
   the weather tool is present in the context, and no duplicate weather tool
   is created."
| answer weatherTools before promptHadCapabilities |
Stdio stdout nextPutAll: '--- A: build a tool ---'; lf.
answer := [ AgentGateway ask: 'make me a weather widget for Tokyo showing the current temperature (use a reusable tool for the fetch)' ]
	on: Error do: [ :e | 'FAILED: ' , e messageText ].
Stdio stdout nextPutAll: answer; lf.
weatherTools := AgentTool tools select: [ :t |
	(t name asLowercase includesSubstring: 'weather')
		or: [ (t purpose ifNil: [ '' ]) asLowercase includesSubstring: 'weather' ] ].
Stdio stdout nextPutAll: 'weather tools after A: '.
weatherTools do: [ :t | Stdio stdout nextPutAll: t name , ' ' ].
Stdio stdout lf.

Stdio stdout nextPutAll: '--- B: reuse it ---'; lf.
promptHadCapabilities := (AgentGateway new systemPrompt includesSubstring: 'Capabilities you''ve built')
	and: [ weatherTools notEmpty and: [ AgentGateway new systemPrompt includesSubstring: weatherTools anyOne name ] ].
Stdio stdout nextPutAll: 'capabilities section lists the weather tool: ' , promptHadCapabilities printString; lf.
before := weatherTools size.
answer := [ AgentGateway ask: 'make a widget comparing the current temperature in Tokyo and London' ]
	on: Error do: [ :e | 'FAILED: ' , e messageText ].
Stdio stdout nextPutAll: answer; lf.
weatherTools := AgentTool tools select: [ :t |
	(t name asLowercase includesSubstring: 'weather')
		or: [ (t purpose ifNil: [ '' ]) asLowercase includesSubstring: 'weather' ] ].
Stdio stdout nextPutAll: 'weather tools after B: '.
weatherTools do: [ :t | Stdio stdout nextPutAll: t name , ' ' ].
Stdio stdout lf.
Stdio stdout nextPutAll: (((weatherTools size = before) and: [ before >= 1 ])
	ifTrue: [ 'REUSE OK (no duplicate weather tool)' ]
	ifFalse: [ 'REBUILT / no tool (before=' , before printString , ' after=' , weatherTools size printString , ')' ]); lf.
Smalltalk exitSuccess
