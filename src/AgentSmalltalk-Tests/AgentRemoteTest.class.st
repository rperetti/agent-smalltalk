Class {
	#name : 'AgentRemoteTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-Tests',
	#package : 'AgentSmalltalk-Tests'
}

{ #category : 'tests' }
AgentRemoteTest >> testPingResponds [
	| response |
	response := AgentRemote handleRequest: (ZnRequest get: '/ping').
	self assert: response status equals: 200.
	self assert: (response entity contents includesSubstring: 'alive')
]

{ #category : 'tests' }
AgentRemoteTest >> testEvalEvaluatesBody [
	| request response |
	request := ZnRequest post: '/eval'.
	request entity: (ZnEntity text: '3 + 4').
	response := AgentRemote handleRequest: request.
	self assert: response status equals: 200.
	self assert: response entity contents equals: 'RESULT: 7'
]

{ #category : 'tests' }
AgentRemoteTest >> testUnknownPathIsNotFound [
	self assert: (AgentRemote handleRequest: (ZnRequest get: '/nope')) status equals: 404
]

{ #category : 'tests' }
AgentRemoteTest >> testUpdateRequiresPost [
	self assert: (AgentRemote handleRequest: (ZnRequest get: '/update')) status equals: 404
]

{ #category : 'tests' }
AgentRemoteTest >> testServerRefusesHeadlessSessions [
	"In the non-interactive test run, ensureRunning must be a no-op."
	self assert: AgentRemote ensureRunning isNil
]

{ #category : 'tests' }
AgentRemoteTest >> testUpdaterConfiguration [
	self assert: (AgentUpdater packageNames includes: 'AgentSmalltalk-Core').
	self assert: AgentUpdater srcDirectory exists.
	self deny: AgentUpdater isInteractive
]
