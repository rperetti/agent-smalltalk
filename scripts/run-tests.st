"Run the SUnit suite headless; exit nonzero on failure."
| suite result |
Stdio stdout nextPutAll: 'AS_LOAD_PHASE SUnit execution'; lf.
suite := TestSuite new.
#(AgentSandboxTest AgentGatewayTest AgentImageSearchTest AgentFactTest AgentCanvasSelectionTest AgentNoteTest AgentUndoResizeTest AgentRemoteTest AgentSystemMessageTest AgentKnowledgeTest AgentKnowledgeCatalogTest AgentToolTest AgentSpotlightTest AgentAutomationTest AgentDependencyLoadTest AgentPortableTextTest) do: [ :sym |
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
