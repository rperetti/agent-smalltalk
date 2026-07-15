"
I make the gateway's pre-request ordering observable without copying an image.
Tests use me to keep the backup-before-catalog safety contract deterministic.
"
Class {
	#name : 'AgentGatewayLifecycleProbe',
	#superclass : 'AgentGateway',
	#instVars : [
		'events'
	],
	#category : 'AgentSmalltalk-Tests',
	#package : 'AgentSmalltalk-Tests'
}

{ #category : 'running' }
AgentGatewayLifecycleProbe >> backupImage [
	events add: #backup
]

{ #category : 'accessing' }
AgentGatewayLifecycleProbe >> events [
	^ events asArray
]

{ #category : 'initialization' }
AgentGatewayLifecycleProbe >> initialize [
	super initialize.
	events := OrderedCollection new
]

{ #category : 'running' }
AgentGatewayLifecycleProbe >> resetKnowledgeCatalog [
	events add: #knowledgeSnapshot.
	^ super resetKnowledgeCatalog
]
