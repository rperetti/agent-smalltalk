"Run the SUnit suite headless; exit nonzero on failure."
| suite result |
suite := TestSuite new.
#(AgentSandboxTest AgentGatewayTest AgentImageSearchTest AgentFactTest AgentCanvasSelectionTest AgentNoteTest AgentUndoResizeTest AgentRemoteTest AgentSystemMessageTest AgentKnowledgeTest AgentToolTest AgentSpotlightTest) do: [ :sym |
	(Smalltalk globals at: sym ifAbsent: [ nil ])
		ifNotNil: [ :cls | suite addTests: cls suite tests ] ].
result := suite run.
Stdio stdout nextPutAll: result printString; lf.
result hasPassed
	ifTrue: [ Smalltalk exitSuccess ]
	ifFalse: [
		result failures , result errors asOrderedCollection do: [ :t |
			Stdio stdout nextPutAll: 'FAILED: ' , t printString; lf ].
		Smalltalk exitFailure ]
