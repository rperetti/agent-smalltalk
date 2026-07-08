"
Deterministic Messages API transport used by AgentGatewayTest. I record every
payload and answer a scripted response sequence, so tests exercise the complete
gateway/tool loop without credentials, network access, latency, or cost.
"
Class {
	#name : 'AgentGatewayFakeTransport',
	#superclass : 'Object',
	#instVars : [
		'responses',
		'payloads'
	],
	#category : 'AgentSmalltalk-Tests',
	#package : 'AgentSmalltalk-Tests'
}

{ #category : 'instance creation' }
AgentGatewayFakeTransport class >> responses: aCollection [
	^ self new responses: aCollection
]

{ #category : 'initialization' }
AgentGatewayFakeTransport >> initialize [
	super initialize.
	responses := OrderedCollection new.
	payloads := OrderedCollection new
]

{ #category : 'accessing' }
AgentGatewayFakeTransport >> responses: aCollection [
	responses := aCollection asOrderedCollection
]

{ #category : 'accessing' }
AgentGatewayFakeTransport >> payloads [
	^ payloads
]

{ #category : 'posting' }
AgentGatewayFakeTransport >> postPayload: payload apiKey: apiKey [
	payloads add: payload.
	responses ifEmpty: [ self error: 'No scripted gateway response remains' ].
	^ responses removeFirst
]
