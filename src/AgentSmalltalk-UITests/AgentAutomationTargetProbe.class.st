"
Small automatable widget fixture. It intentionally exposes only the ordinary
#refresh method so tests prove the base AgentWidget automation hook delegates
to existing widget behavior instead of requiring routine-specific code.
"
Class {
	#name : 'AgentAutomationTargetProbe',
	#superclass : 'AgentWidget',
	#instVars : [
		'refreshCount',
		'refreshResult'
	],
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'initialization' }
AgentAutomationTargetProbe >> initialize [
	super initialize.
	refreshCount := 0.
	refreshResult := nil
]

{ #category : 'accessing' }
AgentAutomationTargetProbe >> refreshCount [
	^ refreshCount
]

{ #category : 'accessing' }
AgentAutomationTargetProbe >> refreshResult: anAgentAutomationResult [
	refreshResult := anAgentAutomationResult
]

{ #category : 'refreshing' }
AgentAutomationTargetProbe >> refresh [
	refreshCount := refreshCount + 1.
	^ refreshResult
]

