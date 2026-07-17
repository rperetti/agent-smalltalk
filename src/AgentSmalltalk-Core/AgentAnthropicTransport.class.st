"
I translate AgentGateway's canonical inference protocol to the Anthropic
Messages API. I own its payload, headers, response validation, and HTTP
resource lifetime; the gateway never needs to interpret Messages API fields.
"
Class {
	#name : 'AgentAnthropicTransport',
	#superclass : 'AgentInferenceProvider',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentAnthropicTransport >> apiKeyEnvironmentVariable [
	^ 'ANTHROPIC_API_KEY'
]

{ #category : 'prompt caching' }
AgentAnthropicTransport >> cacheConfigurationForModel: aModel stableInstructions: stableInstructions tools: tools generationSettings: generationSettings [
	"The Messages API derives its cache key from the request prefix. Keep the
	identity visible in gateway metrics so a changed model, base prompt, tool
	schema, or relevant generation setting has an explainable invalidation."
	| toolSource |
	toolSource := tools
		ifNil: [ 'tools-disabled' ]
		ifNotNil: [ STONJSON toString: tools ].
	^ {
		'enabled' -> true.
		'provider' -> self providerName.
		'cache_control' -> self stablePromptCacheControl.
		'identity' -> ({
			'model' -> aModel.
			'base_prompt_revision' -> (self revisionFor: stableInstructions).
			'tool_schema_revision' -> (self revisionFor: toolSource).
			'generation_settings' -> generationSettings } asDictionary).
		'stable_prefix' -> ({
			'instruction_characters' -> stableInstructions size.
			'tool_schema_characters' -> toolSource size } asDictionary).
		'retention' -> ({
			'kind' -> 'ephemeral'.
			'ttl' -> '5m provider default' } asDictionary) }
		asDictionary
]

{ #category : 'validation' }
AgentAnthropicTransport >> canonicalResponseFrom: rawResponse [
	| content canonicalContent response |
	(rawResponse respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'response must be an object' ].
	content := rawResponse at: 'content' ifAbsent: [
		^ self malformedResponse: 'response has no content' ].
	(content isArray or: [ content isKindOf: OrderedCollection ]) ifFalse: [
		^ self malformedResponse: 'content must be an array' ].
	canonicalContent := (content collect: [ :block |
		self canonicalBlockFrom: block ]) reject: [ :block | block isNil ].
	response := self
		validatedCanonicalResponseWithContent: canonicalContent
		usage: (rawResponse at: 'usage' ifAbsent: [ Dictionary new ]).
	"The gateway must not interpret provider reasoning, but the Messages API
	requires its assistant content to survive the following tool-result turn.
	Keep the original response as opaque continuation state for this adapter."
	response at: 'continuation_state' put: ({
		'provider' -> self providerName.
		'assistant_content' -> content asArray } asDictionary).
	^ response
]

{ #category : 'validation' }
AgentAnthropicTransport >> canonicalBlockFrom: block [
	| type |
	(block respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'content blocks must be objects' ].
	type := block at: 'type' ifAbsent: [
		^ self malformedResponse: 'content block has no type' ].
	type = 'text' ifTrue: [
		^ {
			'type' -> 'text'.
			'text' -> (block at: 'text' ifAbsent: [
				self malformedResponse: 'text block has no text' ]) } asDictionary ].
	type = 'tool_use' ifTrue: [
		^ {
			'type' -> 'tool_use'.
			'id' -> (block at: 'id' ifAbsent: [
				self malformedResponse: 'tool_use block has no id' ]).
			'name' -> (block at: 'name' ifAbsent: [
				self malformedResponse: 'tool_use block has no name' ]).
			'input' -> (block at: 'input' ifAbsent: [
				self malformedResponse: 'tool_use block has no input' ]) } asDictionary ].
	(type = 'thinking' or: [ type = 'redacted_thinking' ]) ifTrue: [
		"Opaque provider continuation state. It is deliberately absent from the
		canonical agent loop, but retained verbatim in continuation_state."
		^ nil ].
	self malformedResponse: 'unsupported content block type ' , type printString
]

{ #category : 'translation' }
AgentAnthropicTransport >> anthropicMessageFromCanonical: message [
	| role continuationState assistantContent translated |
	(message respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'canonical request message must be an object' ].
	role := message at: 'role' ifAbsent: [
		^ self malformedResponse: 'canonical request message has no role' ].
	translated := message copy.
	continuationState := translated
		removeKey: 'continuation_state'
		ifAbsent: [ ^ translated ].
	role = 'assistant' ifFalse: [
		^ self malformedResponse: 'continuation state belongs only on an assistant message' ].
	(continuationState respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'continuation state must be an object' ].
	(continuationState at: 'provider' ifAbsent: [ nil ]) = self providerName
		ifFalse: [ ^ self malformedResponse: 'continuation state belongs to another provider' ].
	assistantContent := continuationState at: 'assistant_content' ifAbsent: [
		^ self malformedResponse: 'continuation state has no assistant content' ].
	(assistantContent isArray or: [ assistantContent isKindOf: OrderedCollection ])
		ifFalse: [ ^ self malformedResponse: 'continuation assistant content must be an array' ].
	translated at: 'content' put: assistantContent asArray.
	^ translated
]

{ #category : 'translation' }
AgentAnthropicTransport >> anthropicMessagesFromCanonical: messages [
	^ messages collect: [ :message |
		self anthropicMessageFromCanonical: message ]
]

{ #category : 'accessing' }
AgentAnthropicTransport >> defaultModel [
	^ 'claude-sonnet-5'
]

{ #category : 'inference' }
AgentAnthropicTransport >> exchangeFor: aCanonicalRequest apiKey: apiKey [
	| payload rawResponse |
	payload := self
		requestPayloadForModel: (aCanonicalRequest at: 'model')
		maxTokens: (aCanonicalRequest at: 'max_output_tokens')
		stableInstructions: ((aCanonicalRequest at: 'system') at: 'stable')
		dynamicInstructions: ((aCanonicalRequest at: 'system') at: 'dynamic')
		messages: (aCanonicalRequest at: 'messages')
		tools: (aCanonicalRequest at: 'tools').
	rawResponse := self
		postPayload: payload
		apiKey: apiKey
		timeoutSeconds: (aCanonicalRequest at: 'timeout_seconds').
	^ {
		'request_payload' -> payload.
		'raw_response' -> rawResponse.
		'response' -> (self canonicalResponseFrom: rawResponse) }
		asDictionary
]

{ #category : 'posting' }
AgentAnthropicTransport >> postPayload: payload apiKey: apiKey [
	^ self postPayload: payload apiKey: apiKey timeoutSeconds: 180
]

{ #category : 'posting' }
AgentAnthropicTransport >> postPayload: payload apiKey: apiKey timeoutSeconds: timeoutSeconds [
	^ self
		postJSONPayload: payload
		to: 'https://api.anthropic.com/v1/messages'
		headers: ({
			'x-api-key' -> apiKey.
			'anthropic-version' -> '2023-06-01' } asDictionary)
		timeoutSeconds: timeoutSeconds
]

{ #category : 'prompt caching' }
AgentAnthropicTransport >> providerName [
	^ 'anthropic-messages'
]

{ #category : 'prompt caching' }
AgentAnthropicTransport >> requestPayloadForModel: aModel maxTokens: maxTokens stableInstructions: stableInstructions dynamicInstructions: dynamicInstructions messages: messages tools: tools [
	"Anthropic caches the full request prefix in tools, system, messages order.
	The marked base-prompt block therefore also covers stable tool schemas, but
	nothing after it: the appendix, user data, history, and tool results remain
	a fresh suffix for every request."
	| payload |
	payload := {
		'model' -> aModel.
		'max_tokens' -> maxTokens.
		'system' -> {
			{
				'type' -> 'text'.
				'text' -> stableInstructions.
				'cache_control' -> self stablePromptCacheControl } asDictionary.
			{
				'type' -> 'text'.
				'text' -> dynamicInstructions } asDictionary }.
		'messages' -> (self anthropicMessagesFromCanonical: messages) } asDictionary.
	tools ifNotNil: [ payload at: 'tools' put: tools ].
	^ payload
]

{ #category : 'prompt caching' }
AgentAnthropicTransport >> revisionFor: source [
	"A compact, deterministic evidence label rather than a security digest.
	Anthropic owns the actual prefix hash; these values make local invalidation
	observable in logs and paid evaluations."
	^ 'characters-' , source size printString , '-hash-' , source hash printString
]

{ #category : 'prompt caching' }
AgentAnthropicTransport >> stablePromptCacheControl [
	^ { 'type' -> 'ephemeral' } asDictionary
]
