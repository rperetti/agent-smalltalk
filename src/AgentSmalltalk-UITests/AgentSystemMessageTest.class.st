"
Headless tests for the system's voice: posting, keyed coalescing, corner
pile, and context invisibility (unless selected).
"
Class {
	#name : 'AgentSystemMessageTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentSystemMessageTest >> setUp [
	super setUp.
	AgentCanvas reset
]

{ #category : 'running' }
AgentSystemMessageTest >> tearDown [
	AgentCanvas reset.
	super tearDown
]

{ #category : 'tests' }
AgentSystemMessageTest >> testPostCreatesGraySticky [
	| m |
	m := AgentSystemMessage post: 'image updated'.
	self assert: AgentCanvas current systemMessages size equals: 1.
	self assert: m body equals: 'image updated'.
	self assert: (m describe includesSubstring: 'system: image updated')
]

{ #category : 'tests' }
AgentSystemMessageTest >> testKeyedMessagesCoalesce [
	AgentSystemMessage post: 'updated once' key: #imageUpdate.
	AgentSystemMessage post: 'updated again' key: #imageUpdate.
	self assert: AgentCanvas current systemMessages size equals: 1.
	self assert: AgentCanvas current systemMessages first body equals: 'updated again'.
	self assert: (AgentCanvas current systemMessages first describe includesSubstring: '(x2)')
]

{ #category : 'tests' }
AgentSystemMessageTest >> testKeylessMessagesAccumulate [
	AgentSystemMessage post: 'one'.
	AgentSystemMessage post: 'two'.
	self assert: AgentCanvas current systemMessages size equals: 2
]

{ #category : 'tests' }
AgentSystemMessageTest >> testOutOfContextUnlessSelected [
	| m |
	m := AgentSystemMessage post: 'the quiet announcement'.
	self deny: (AgentCanvas current contextDescription includesSubstring: 'the quiet announcement').
	AgentCanvas current selectWidgets: { m }.
	self assert: (AgentCanvas current contextDescription includesSubstring: 'the quiet announcement')
]

{ #category : 'tests' }
AgentSystemMessageTest >> testNotCountedAsFactOrNote [
	AgentSystemMessage post: 'x'.
	self assert: AgentCanvas current facts isEmpty.
	self assert: AgentCanvas current notes isEmpty
]

{ #category : 'tests' }
AgentSystemMessageTest >> testUpdaterPostsWithImageUpdateKey [
	AgentUpdater postUpdateMessage.
	AgentUpdater postUpdateMessage.
	self assert: AgentCanvas current systemMessages size equals: 1.
	self assert: AgentCanvas current systemMessages first key equals: #imageUpdate
]

{ #category : 'tests' }
AgentSystemMessageTest >> testSafeUiUpdateTurnsErrorIntoSystemMessage [
	AgentWidget new runOnUiThreadSafely: [ self error: 'async boom' ].
	self assert: AgentCanvas current systemMessages size equals: 1.
	self assert: (AgentCanvas current systemMessages first body
		includesSubstring: 'async boom').
	self assert: (AgentCanvas current systemMessages first body
		includesSubstring: 'AgentWidget')
]

{ #category : 'tests' }
AgentSystemMessageTest >> testGatewaySurfacesAsyncFailureOnceWithinOneGateway [
	| gateway toolUse firstResult secondResult |
	gateway := AgentGateway new.
	AgentSystemMessage
		post: 'Widget update failed in ProbeWidget: broken label'
		key: #'widgetUpdateFailure-ProbeWidget'.
	toolUse := self asyncFailureToolUse.
	firstResult := gateway runTool: toolUse.
	secondResult := gateway runTool: toolUse.
	self assert: ((firstResult at: 'content')
		includesSubstring: 'asynchronous widget update failure').
	self assert: ((firstResult at: 'content')
		includesSubstring: 'broken label').
	self deny: ((secondResult at: 'content')
		includesSubstring: 'asynchronous widget update failure')
]

{ #category : 'tests' }
AgentSystemMessageTest >> testGatewayDeliversAsyncFailureAcrossGatewayInstancesOnce [
	| firstGateway secondGateway firstResult secondResult |
	firstGateway := AgentGateway new.
	secondGateway := AgentGateway new.
	AgentSystemMessage
		post: 'Widget update failed in ProbeWidget: broken label'
		key: #'widgetUpdateFailure-ProbeWidget'.
	firstResult := firstGateway runTool: self asyncFailureToolUse.
	secondResult := secondGateway runTool: self asyncFailureToolUse.
	self assert: ((firstResult at: 'content')
		includesSubstring: 'broken label').
	self deny: ((secondResult at: 'content')
		includesSubstring: 'asynchronous widget update failure')
]

{ #category : 'tests' }
AgentSystemMessageTest >> testAsyncFailureAfterPreviousToolResultArrivesOnNextRequestOnce [
	| firstGateway nextGateway previousResult nextResult repeatedResult |
	firstGateway := AgentGateway new.
	nextGateway := AgentGateway new.
	previousResult := firstGateway runTool: self asyncFailureToolUse.
	AgentSystemMessage
		post: 'Widget update failed in ProbeWidget: late failure'
		key: #'widgetUpdateFailure-ProbeWidget'.
	nextResult := nextGateway runTool: self asyncFailureToolUse.
	repeatedResult := nextGateway runTool: self asyncFailureToolUse.
	self deny: ((previousResult at: 'content')
		includesSubstring: 'asynchronous widget update failure').
	self assert: ((nextResult at: 'content')
		includesSubstring: 'late failure').
	self deny: ((repeatedResult at: 'content')
		includesSubstring: 'asynchronous widget update failure')
]

{ #category : 'tests' }
AgentSystemMessageTest >> testCoalescedAsyncFailureDeliversTheLaterOccurrenceOnce [
	| gateway firstResult laterResult repeatedResult |
	gateway := AgentGateway new.
	AgentSystemMessage
		post: 'Widget update failed in ProbeWidget: first failure'
		key: #'widgetUpdateFailure-ProbeWidget'.
	firstResult := gateway runTool: self asyncFailureToolUse.
	AgentSystemMessage
		post: 'Widget update failed in ProbeWidget: later failure'
		key: #'widgetUpdateFailure-ProbeWidget'.
	laterResult := gateway runTool: self asyncFailureToolUse.
	repeatedResult := gateway runTool: self asyncFailureToolUse.
	self assert: ((firstResult at: 'content')
		includesSubstring: 'first failure').
	self assert: ((laterResult at: 'content')
		includesSubstring: 'later failure').
	self deny: ((repeatedResult at: 'content')
		includesSubstring: 'asynchronous widget update failure')
]

{ #category : 'tests' }
AgentSystemMessageTest >> testDeletingAndRecreatingAsyncFailureStartsNewOccurrence [
	| gateway recreatedResult repeatedResult originalMessage |
	gateway := AgentGateway new.
	originalMessage := AgentSystemMessage
		post: 'Widget update failed in ProbeWidget: original failure'
		key: #'widgetUpdateFailure-ProbeWidget'.
	gateway runTool: self asyncFailureToolUse.
	originalMessage removeFromParent.
	AgentSystemMessage
		post: 'Widget update failed in ProbeWidget: recreated failure'
		key: #'widgetUpdateFailure-ProbeWidget'.
	recreatedResult := gateway runTool: self asyncFailureToolUse.
	repeatedResult := gateway runTool: self asyncFailureToolUse.
	self assert: ((recreatedResult at: 'content')
		includesSubstring: 'recreated failure').
	self deny: ((repeatedResult at: 'content')
		includesSubstring: 'asynchronous widget update failure')
]

{ #category : 'support' }
AgentSystemMessageTest >> asyncFailureToolUse [
	^ {
		'id' -> 'async-probe'.
		'name' -> 'evaluate_smalltalk'.
		'input' -> ({ 'code' -> '3 + 4' } asDictionary) } asDictionary
]

{ #category : 'tests' }
AgentSystemMessageTest >> testStyledTextHelperAvoidsKeywordPrecedenceTrap [
	| element |
	element := BlTextElement new.
	AgentWidget new
		setText: '18°C'
		on: element
		fontSize: 24.
	self assert: element text asString equals: '18°C'
]

{ #category : 'tests' }
AgentSystemMessageTest >> testPilesAtBottomLeft [
	self assert: AgentSystemMessage pileOrigin equals: 20 @ 640
]
