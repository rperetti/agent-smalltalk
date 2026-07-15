"
I provide instruction-like widget descriptions for deterministic prompt-context
tests. I model hostile text without granting it any behavior.
"
Class {
	#name : 'AgentPromptContextAdversarialProbe',
	#superclass : 'AgentWidget',
	#instVars : [
		'text'
	],
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'accessing' }
AgentPromptContextAdversarialProbe >> text: aString [
	text := aString
]

{ #category : 'agent context' }
AgentPromptContextAdversarialProbe >> describe [
	^ text ifNil: [ '' ]
]
