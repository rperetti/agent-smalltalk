"
Announced on the canvas announcer whenever a fact's body changes -- by the
agent (AgentFact key:body:) or by the user editing the sticky (on focus
loss). Subscribers get the key and the live fact.
"
Class {
	#name : 'AgentFactChanged',
	#superclass : 'Announcement',
	#instVars : [
		'key',
		'fact'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentFactChanged >> key [
	^ key
]

{ #category : 'accessing' }
AgentFactChanged >> key: aSymbol [
	key := aSymbol
]

{ #category : 'accessing' }
AgentFactChanged >> fact [
	^ fact
]

{ #category : 'accessing' }
AgentFactChanged >> fact: anAgentFact [
	fact := anAgentFact
]
