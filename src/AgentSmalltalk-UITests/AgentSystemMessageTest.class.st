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
AgentSystemMessageTest >> testPilesAtBottomLeft [
	self assert: AgentSystemMessage pileOrigin equals: 20 @ 640
]
