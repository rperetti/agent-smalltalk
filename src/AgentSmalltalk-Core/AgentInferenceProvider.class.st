"
I define the provider-neutral inference seam. AgentGateway sends canonical
turns and tool definitions through this protocol; concrete adapters alone own
wire payloads, HTTP details, response translation, and validation.
"
Class {
	#name : 'AgentInferenceProvider',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'instance creation' }
AgentInferenceProvider class >> named: aProviderName [
	| normalized |
	normalized := aProviderName asString trimBoth asLowercase.
	normalized = 'anthropic' ifTrue: [ ^ AgentAnthropicTransport new ].
	normalized = 'openai' ifTrue: [ ^ AgentOpenAITransport new ].
	self error: 'Unknown inference provider ''' , normalized
		, '''. Supported providers: ' , (self providerNames joinUsing: ', ')
]

{ #category : 'accessing' }
AgentInferenceProvider class >> providerNames [
	^ #('anthropic' 'openai')
]

{ #category : 'accessing' }
AgentInferenceProvider >> apiKeyEnvironmentVariable [
	self subclassResponsibility
]

{ #category : 'prompt caching' }
AgentInferenceProvider >> cacheConfigurationForModel: aModel stableInstructions: stableInstructions tools: tools generationSettings: generationSettings [
	self subclassResponsibility
]

{ #category : 'accessing' }
AgentInferenceProvider >> defaultModel [
	self subclassResponsibility
]

{ #category : 'inference' }
AgentInferenceProvider >> exchangeFor: aCanonicalRequest apiKey: apiKey [
	self subclassResponsibility
]

{ #category : 'validation' }
AgentInferenceProvider >> malformedResponse: aString [
	AgentInferenceProviderError
		signal: self providerName , ' returned a malformed response: ' , aString
		retryable: false
		statusCode: nil
]

{ #category : 'posting' }
AgentInferenceProvider >> postJSONPayload: payload to: aUrl headers: headers timeoutSeconds: timeoutSeconds [
	| client body |
	client := ZnClient new.
	body := [
		[ | responseBody statusCode |
			client
				url: aUrl;
				entity: (ZnEntity with: (STONJSON toString: payload) type: ZnMimeType applicationJson);
				timeout: timeoutSeconds.
			headers keysAndValuesDo: [ :key :value |
				client headerAt: key put: value ].
			responseBody := client post.
			client isSuccess ifFalse: [
				statusCode := [ client response status ] on: Error do: [ nil ].
				AgentInferenceProviderError
					signal: self providerName , ' API error: '
						, (client response statusLine printString) , ' — '
						, (responseBody ifNil: [ '<no body>' ]) printString
					retryable: (statusCode = 429 or: [
						statusCode isInteger and: [ statusCode >= 500 ] ])
					statusCode: statusCode ].
			responseBody ]
			on: Error
			do: [ :error |
				(error isKindOf: AgentInferenceProviderError)
					ifTrue: [ error pass ]
					ifFalse: [
						AgentInferenceProviderError
							signal: self providerName , ' network error: ' , error messageText
							retryable: true
							statusCode: nil ] ] ]
		ensure: [
			[ client close ] on: Error do: [ :ignored |  ] ].
	^ [ STONJSON fromString: body ]
		on: Error
		do: [ :error |
			AgentInferenceProviderError
				signal: self providerName , ' returned invalid JSON: ' , error messageText
				retryable: false
				statusCode: nil ]
]

{ #category : 'accessing' }
AgentInferenceProvider >> providerName [
	self subclassResponsibility
]

{ #category : 'usage' }
AgentInferenceProvider >> usageFromResponse: response [
	| usage normalized |
	normalized := Dictionary new.
	#(input_tokens output_tokens cache_creation_input_tokens cache_read_input_tokens)
		do: [ :key | normalized at: key put: 0 ].
	(response respondsTo: #at:ifAbsent:) ifFalse: [ ^ normalized ].
	usage := response at: 'usage' ifAbsent: [ ^ normalized ].
	(usage respondsTo: #at:ifAbsent:) ifFalse: [ ^ normalized ].
	normalized keysAndValuesDo: [ :key :ignored |
		normalized at: key put: (self usageValueAt: key in: usage) ].
	^ normalized
]

{ #category : 'usage' }
AgentInferenceProvider >> usageValueAt: key in: usage [
	| value |
	value := usage at: key ifAbsent: [ 0 ].
	^ (value isInteger and: [ value >= 0 ])
		ifTrue: [ value ]
		ifFalse: [ 0 ]
]

{ #category : 'validation' }
AgentInferenceProvider >> validatedCanonicalResponseWithContent: content usage: usage [
	(content isArray or: [ content isKindOf: OrderedCollection ]) ifFalse: [
		^ self malformedResponse: 'content must be an array' ].
	content do: [ :block | self validateCanonicalBlock: block ].
	^ {
		'schema' -> 'agent-inference-response/v1'.
		'content' -> content asArray.
		'usage' -> usage } asDictionary
]

{ #category : 'validation' }
AgentInferenceProvider >> validateCanonicalBlock: block [
	| type |
	(block respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'content blocks must be objects' ].
	type := block at: 'type' ifAbsent: [
		^ self malformedResponse: 'content block has no type' ].
	type = 'text' ifTrue: [
		((block at: 'text' ifAbsent: [ nil ]) isKindOf: String) ifFalse: [
			self malformedResponse: 'text block has no string text' ].
		^ self ].
	type = 'tool_use' ifTrue: [
		self validateCanonicalToolUse: block.
		^ self ].
	self malformedResponse: 'unsupported content block type ' , type printString
]

{ #category : 'validation' }
AgentInferenceProvider >> validateCanonicalToolUse: block [
	| id name input |
	id := block at: 'id' ifAbsent: [ nil ].
	name := block at: 'name' ifAbsent: [ nil ].
	input := block at: 'input' ifAbsent: [ nil ].
	((id isKindOf: String) and: [ id trimBoth isEmpty not ]) ifFalse: [
		^ self malformedResponse: 'tool_use block has no non-empty id' ].
	((name isKindOf: String) and: [ name trimBoth isEmpty not ]) ifFalse: [
		^ self malformedResponse: 'tool_use block has no non-empty name' ].
	(input respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'tool_use input must be an object' ]
]
