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
	self assert: response entity contents equals: 'agent-smalltalk alive update-v1'
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
AgentRemoteTest >> testStopIsIdempotent [
	"ensureRunning itself is integration-tested by pinging a live session;
	here we only assert lifecycle calls never raise (port state varies)."
	self shouldnt: [ AgentRemote stop. AgentRemote stop ] raise: Error
]

{ #category : 'tests' }
AgentRemoteTest >> testUpdaterConfiguration [
	self assert: (AgentUpdater packageNames includes: 'AgentSmalltalk-Core').
	self assert: (AgentUpdater packageNames includes: 'AgentSmalltalk-UICompatibility').
	self assert: AgentUpdater srcDirectory exists.
	self deny: AgentUpdater isInteractive
]

{ #category : 'tests' }
AgentRemoteTest >> testBuildManifestMustMatchTheGeneratedMarker [
	| manifest |
	manifest := 'AS_UPDATE_V1 git:deadbeef sha256:0123456789abcdef'.
	self assert: (AgentUpdater hasValidBuildManifest: manifest).
	self assert: (AgentUpdater manifestsMatch: manifest expected: manifest).
	self deny: (AgentUpdater manifestsMatch: manifest expected: 'AS_UPDATE_V1 git:other sha256:0123456789abcdef').
	self deny: (AgentUpdater verifyLoadedManifest: manifest)
]

{ #category : 'tests' }
AgentRemoteTest >> testUpdateCandidateBodyRequiresSourceAndManifest [
	| request candidate manifest |
	manifest := 'AS_UPDATE_V1 git:deadbeef sha256:0123456789abcdef'.
	request := ZnRequest post: '/update'.
	request entity: (ZnEntity text: '/tmp/agent-candidate' , String cr , manifest).
	candidate := AgentRemote updateCandidateFrom: request.
	self assert: candidate first equals: '/tmp/agent-candidate'.
	self assert: candidate second equals: manifest.
	request entity: (ZnEntity text: '/tmp/agent-candidate').
	self
		should: [ AgentRemote updateCandidateFrom: request ]
		raise: Error
]
