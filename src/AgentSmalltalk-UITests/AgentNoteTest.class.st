"
Headless tests for answer notes: creation, provenance, placement policy,
context visibility (out by default, in when selected), and the gateway's
pure-answer heuristic.
"
Class {
	#name : 'AgentNoteTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentNoteTest >> setUp [
	super setUp.
	AgentCanvas reset
]

{ #category : 'running' }
AgentNoteTest >> tearDown [
	AgentCanvas reset.
	super tearDown
]

{ #category : 'tests' }
AgentNoteTest >> testNoteCreationAndDescribe [
	| note |
	note := AgentNote question: 'what is the score' answer: 'Australia 1-1 Egypt'.
	self assert: AgentCanvas current notes size equals: 1.
	self assert: note body equals: 'Australia 1-1 Egypt'.
	self assert: (note describe includesSubstring: 'note re: ''what is the score''').
	self assert: (note describe includesSubstring: 'Australia 1-1 Egypt')
]

{ #category : 'tests' }
AgentNoteTest >> testPileWhenNoSelection [
	AgentNote question: 'q1' answer: 'a1'.
	self assert: AgentNote nextPosition equals: (940 + 16) @ (20 + 26)
]

{ #category : 'tests' }
AgentNoteTest >> testReplySelectsSelfAndScopesContext [
	| note |
	note := AgentNote question: 'what is the score' answer: 'Australia 1-1 Egypt'.
	note reply.
	"Reply scopes the LLM context to this note (via selection), and a
	follow-up answer would land beside it."
	self assert: (AgentCanvas current selectedWidgets includes: note).
	self assert: (Smalltalk globals at: #Selection1) identicalTo: note.
	self assert: (AgentCanvas current contextDescription includesSubstring: 'Australia 1-1 Egypt').
	self assert: AgentNote nextPosition equals: note position + (260 @ 0)
]

{ #category : 'tests' }
AgentNoteTest >> testPlacementNearSelection [
	| w |
	w := AgentWidget new.
	AgentCanvas current addWidget: w.
	AgentCanvas current selectWidgets: { w }.
	self assert: AgentNote nextPosition equals: w position + (260 @ 0)
]

{ #category : 'tests' }
AgentNoteTest >> testNotesOutOfContextByDefault [
	AgentNote question: 'q' answer: 'the secret answer'.
	self deny: (AgentCanvas current contextDescription includesSubstring: 'the secret answer')
]

{ #category : 'tests' }
AgentNoteTest >> testSelectedNoteFeedsContext [
	| note |
	note := AgentNote question: 'q' answer: 'the secret answer'.
	AgentCanvas current selectWidgets: { note }.
	self assert: (AgentCanvas current contextDescription includesSubstring: 'the secret answer')
]

{ #category : 'tests' }
AgentNoteTest >> testGatewayNotesPureAnswers [
	| gateway before |
	gateway := AgentGateway new.
	before := gateway canvasWidgetsSnapshot.
	gateway noteIfPureAnswer: 'the score is 1-1' for: 'what is the score' since: before.
	self assert: AgentCanvas current notes size equals: 1
]

{ #category : 'tests' }
AgentNoteTest >> testGatewaySkipsNoteWhenWidgetWasCreated [
	| gateway before |
	gateway := AgentGateway new.
	before := gateway canvasWidgetsSnapshot.
	AgentCanvas current addWidget: AgentWidget new.
	gateway noteIfPureAnswer: 'done, made you a widget' for: 'make a widget' since: before.
	self assert: AgentCanvas current notes isEmpty
]

{ #category : 'tests' }
AgentNoteTest >> testGatewaySkipsEmptyAnswers [
	| gateway |
	gateway := AgentGateway new.
	gateway noteIfPureAnswer: '   ' for: 'anything' since: gateway canvasWidgetsSnapshot.
	self assert: AgentCanvas current notes isEmpty
]
