"
Test fixture whose action block makes AgentAutomation execution deterministic.
"
Class {
	#name : 'AgentAutomationTestProbe',
	#superclass : 'AgentAutomation',
	#instVars : [
		'action',
		'runCount'
	],
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'initialization' }
AgentAutomationTestProbe >> initialize [
	super initialize.
	action := [ AgentAutomationResult unchanged: 'ok' ].
	runCount := 0
]

{ #category : 'accessing' }
AgentAutomationTestProbe >> action: aBlock [
	action := aBlock
]

{ #category : 'accessing' }
AgentAutomationTestProbe >> runCount [
	^ runCount
]

{ #category : 'running' }
AgentAutomationTestProbe >> run [
	runCount := runCount + 1.
	^ action value
]
