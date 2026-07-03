Class {
	#name : 'AgentSandboxTest',
	#superclass : 'TestCase',
	#instVars : [
		'sandbox'
	],
	#category : 'AgentSmalltalk-Tests',
	#package : 'AgentSmalltalk-Tests'
}

{ #category : 'running' }
AgentSandboxTest >> setUp [
	super setUp.
	sandbox := AgentSandbox new
]

{ #category : 'tests' }
AgentSandboxTest >> testEvaluateAnswersResult [
	self assert: (sandbox evaluate: '3 + 4') equals: 'RESULT: 7'
]

{ #category : 'tests' }
AgentSandboxTest >> testEvaluateKeepsStateInImage [
	sandbox evaluate: 'Smalltalk globals at: #AgentSandboxTestProbe put: 42'.
	self assert: (sandbox evaluate: 'Smalltalk globals at: #AgentSandboxTestProbe')
		equals: 'RESULT: 42'.
	Smalltalk globals removeKey: #AgentSandboxTestProbe
]

{ #category : 'tests' }
AgentSandboxTest >> testRuntimeErrorIsReported [
	| report |
	report := sandbox evaluate: '1 zork'.
	self assert: (report beginsWith: 'ERROR:').
	self assert: (report includesSubstring: 'zork')
]

{ #category : 'tests' }
AgentSandboxTest >> testSyntaxErrorIsReported [
	| report |
	report := sandbox evaluate: '3 + + 4]]'.
	self assert: (report beginsWith: 'ERROR:')
]

{ #category : 'tests' }
AgentSandboxTest >> testTimeoutIsReported [
	| report |
	sandbox timeoutSeconds: 1.
	report := sandbox evaluate: '[ true ] whileTrue'.
	self assert: (report beginsWith: 'ERROR: evaluation timed out')
]

{ #category : 'tests' }
AgentSandboxTest >> testSafePrintSurvivesBrokenPrintString [
	| report |
	report := sandbox evaluate: 'Object new instVarNamed: #nope'.
	"Whatever happens, the answer must be a RESULT: or ERROR: string, never a walkback."
	self assert: ((report beginsWith: 'RESULT:') or: [ report beginsWith: 'ERROR:' ])
]
