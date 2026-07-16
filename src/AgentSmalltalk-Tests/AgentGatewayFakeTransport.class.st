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
		'payloads',
		'cacheEnabled'
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
	payloads := OrderedCollection new.
	cacheEnabled := false
]

{ #category : 'prompt caching' }
AgentGatewayFakeTransport >> cacheConfigurationForModel: aModel stableInstructions: stableInstructions tools: tools generationSettings: generationSettings [
	"The scripted transport can exercise both the safe fallback and Anthropic's
	explicit-block payload shape without making a provider call."
	| configuration |
	configuration := AgentAnthropicTransport new
		cacheConfigurationForModel: aModel
		stableInstructions: stableInstructions
		tools: tools
		generationSettings: generationSettings.
	configuration
		at: 'enabled' put: cacheEnabled;
		at: 'provider' put: 'scripted-fake'.
	cacheEnabled ifFalse: [
		configuration
			at: 'cache_control' put: nil;
			at: 'fallback' put: 'adapter does not support stable prompt caching' ].
	^ configuration
]

{ #category : 'prompt caching' }
AgentGatewayFakeTransport >> cacheEnabled: aBoolean [
	cacheEnabled := aBoolean
]

{ #category : 'prompt caching' }
AgentGatewayFakeTransport >> requestPayloadForModel: aModel maxTokens: maxTokens stableInstructions: stableInstructions dynamicInstructions: dynamicInstructions messages: messages tools: tools [
	| payload |
	payload := {
		'model' -> aModel.
		'max_tokens' -> maxTokens.
		'system' -> (cacheEnabled
			ifTrue: [ {
				{
					'type' -> 'text'.
					'text' -> stableInstructions.
					'cache_control' -> ({ 'type' -> 'ephemeral' } asDictionary) } asDictionary.
				{
					'type' -> 'text'.
					'text' -> dynamicInstructions } asDictionary } ]
			ifFalse: [ stableInstructions , dynamicInstructions ]).
		'messages' -> messages } asDictionary.
	tools ifNotNil: [ payload at: 'tools' put: tools ].
	^ payload
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

{ #category : 'usage' }
AgentGatewayFakeTransport >> usageFromResponse: response [
	"Fixtures use the Messages API's public usage vocabulary while this transport
	still models an adapter that may decline cache support."
	^ AgentAnthropicTransport new usageFromResponse: response
]
