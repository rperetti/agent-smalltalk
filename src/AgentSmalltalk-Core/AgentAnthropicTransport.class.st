"
I am the production HTTP transport for AgentGateway. Keeping network I/O
behind this small protocol makes the agentic loop deterministic in tests:
tests substitute a transport that answers recorded Messages API responses,
while the gateway continues to exercise its real message/tool orchestration.
"
Class {
	#name : 'AgentAnthropicTransport',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

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
		'messages' -> messages } asDictionary.
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

{ #category : 'usage' }
AgentAnthropicTransport >> usageFromResponse: response [
	"Translate only valid, non-negative integer usage values. A malformed
	provider usage envelope must not break a successful model response or turn
	metrics into arbitrary objects."
	| usage translated |
	translated := Dictionary new.
	#(input_tokens output_tokens cache_creation_input_tokens cache_read_input_tokens)
		do: [ :key | translated at: key put: 0 ].
	(response respondsTo: #at:ifAbsent:) ifFalse: [ ^ translated ].
	usage := response at: 'usage' ifAbsent: [ ^ translated ].
	(usage respondsTo: #at:ifAbsent:) ifFalse: [ ^ translated ].
	translated keysAndValuesDo: [ :key :ignored |
		translated at: key put: (self usageValueAt: key in: usage) ].
	^ translated
]

{ #category : 'usage' }
AgentAnthropicTransport >> usageValueAt: key in: usage [
	| value |
	value := usage at: key ifAbsent: [ 0 ].
	^ (value isInteger and: [ value >= 0 ])
		ifTrue: [ value ]
		ifFalse: [ 0 ]
]

{ #category : 'posting' }
AgentAnthropicTransport >> postPayload: payload apiKey: apiKey [
	| client body |
	client := ZnClient new.
	client
		url: 'https://api.anthropic.com/v1/messages';
		headerAt: 'x-api-key' put: apiKey;
		headerAt: 'anthropic-version' put: '2023-06-01';
		entity: (ZnEntity with: (STONJSON toString: payload) type: ZnMimeType applicationJson);
		timeout: 180.
	body := client post.
	client isSuccess ifFalse: [
		self error: 'Anthropic API error: ' , client response statusLine printString
			, ' — ' , (body ifNil: [ '<no body>' ]) printString ].
	^ STONJSON fromString: body
]
