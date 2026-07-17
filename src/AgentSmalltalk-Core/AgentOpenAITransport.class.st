"
I translate AgentGateway's canonical inference protocol to OpenAI Chat
Completions. The gateway sees the same text/tool-use blocks it sees from every
provider; this adapter owns OpenAI's message, function, usage, and HTTP shapes.
"
Class {
	#name : 'AgentOpenAITransport',
	#superclass : 'AgentInferenceProvider',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'translation' }
AgentOpenAITransport >> addCanonicalMessage: message to: translatedMessages [
	| role content |
	role := message at: 'role' ifAbsent: [
		^ self malformedResponse: 'canonical request message has no role' ].
	content := message at: 'content' ifAbsent: [
		^ self malformedResponse: 'canonical request message has no content' ].
	role = 'user' ifTrue: [
		content isString
			ifTrue: [ translatedMessages add: ({
				'role' -> 'user'.
				'content' -> content } asDictionary) ]
			ifFalse: [
				(content isArray or: [ content isKindOf: OrderedCollection ]) ifFalse: [
					^ self malformedResponse: 'user content must be text or tool results' ].
				content do: [ :toolResult |
					translatedMessages add: (self openAIToolResultFrom: toolResult) ] ].
		^ self ].
	role = 'assistant' ifTrue: [
		^ translatedMessages add: (self openAIAssistantMessageFrom: content) ].
	self malformedResponse: 'unsupported canonical message role ' , role printString
]

{ #category : 'accessing' }
AgentOpenAITransport >> apiKeyEnvironmentVariable [
	^ 'OPENAI_API_KEY'
]

{ #category : 'prompt caching' }
AgentOpenAITransport >> cacheConfigurationForModel: aModel stableInstructions: stableInstructions tools: tools generationSettings: generationSettings [
	"OpenAI may apply provider-managed prompt caching, but this adapter does not
	request a cache breakpoint. Keep that fact explicit instead of presenting
	Anthropic's cache-control contract as provider-neutral behavior."
	| toolSource |
	toolSource := tools
		ifNil: [ 'tools-disabled' ]
		ifNotNil: [ STONJSON toString: tools ].
	^ {
		'enabled' -> false.
		'provider' -> self providerName.
		'fallback' -> 'provider-managed caching has no explicit cache breakpoint'.
		'identity' -> ({
			'model' -> aModel.
			'base_prompt_revision' -> (self revisionFor: stableInstructions).
			'tool_schema_revision' -> (self revisionFor: toolSource).
			'generation_settings' -> generationSettings } asDictionary).
		'stable_prefix' -> ({
			'instruction_characters' -> stableInstructions size.
			'tool_schema_characters' -> toolSource size } asDictionary) }
		asDictionary
]

{ #category : 'validation' }
AgentOpenAITransport >> canonicalResponseFrom: rawResponse [
	| choices choice message content toolCalls canonicalContent |
	(rawResponse respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'response must be an object' ].
	choices := rawResponse at: 'choices' ifAbsent: [
		^ self malformedResponse: 'response has no choices' ].
	(choices isArray or: [ choices isKindOf: OrderedCollection ]) ifFalse: [
		^ self malformedResponse: 'choices must be an array' ].
	choices isEmpty ifTrue: [ ^ self malformedResponse: 'choices is empty' ].
	choice := choices first.
	(choice respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'choice must be an object' ].
	message := choice at: 'message' ifAbsent: [
		^ self malformedResponse: 'choice has no message' ].
	(message respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'choice message must be an object' ].
	canonicalContent := OrderedCollection new.
	content := message at: 'content' ifAbsent: [ nil ].
	content ifNotNil: [
		content isString ifFalse: [
			^ self malformedResponse: 'choice message content must be text or null' ].
		content isEmpty ifFalse: [
			canonicalContent add: ({
				'type' -> 'text'.
				'text' -> content } asDictionary) ] ].
	toolCalls := message at: 'tool_calls' ifAbsent: [ #() ].
	(toolCalls isArray or: [ toolCalls isKindOf: OrderedCollection ]) ifFalse: [
		^ self malformedResponse: 'tool_calls must be an array' ].
	toolCalls do: [ :toolCall |
		canonicalContent add: (self canonicalToolUseFrom: toolCall) ].
	^ self
		validatedCanonicalResponseWithContent: canonicalContent
		usage: (self canonicalUsageFrom: rawResponse)
]

{ #category : 'validation' }
AgentOpenAITransport >> canonicalToolUseFrom: toolCall [
	| function arguments input |
	(toolCall respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'tool call must be an object' ].
	(toolCall at: 'type' ifAbsent: [ 'function' ]) = 'function' ifFalse: [
		^ self malformedResponse: 'tool call type must be function' ].
	function := toolCall at: 'function' ifAbsent: [
		^ self malformedResponse: 'tool call has no function object' ].
	(function respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'tool call function must be an object' ].
	arguments := function at: 'arguments' ifAbsent: [
		^ self malformedResponse: 'tool call has no arguments' ].
	arguments isString ifFalse: [
		^ self malformedResponse: 'tool call arguments must be JSON text' ].
	input := [ STONJSON fromString: arguments ]
		on: Error
		do: [ :error |
			self malformedResponse: 'tool call arguments are invalid JSON: '
				, error messageText ].
	(input respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'tool call arguments must decode to an object' ].
	^ {
		'type' -> 'tool_use'.
		'id' -> (toolCall at: 'id' ifAbsent: [
			self malformedResponse: 'tool call has no id' ]).
		'name' -> (function at: 'name' ifAbsent: [
			self malformedResponse: 'tool call function has no name' ]).
		'input' -> input } asDictionary
]

{ #category : 'usage' }
AgentOpenAITransport >> canonicalUsageFrom: rawResponse [
	| usage promptDetails |
	usage := rawResponse at: 'usage' ifAbsent: [ Dictionary new ].
	(usage respondsTo: #at:ifAbsent:) ifFalse: [ ^ Dictionary new ].
	promptDetails := usage at: 'prompt_tokens_details' ifAbsent: [ Dictionary new ].
	(promptDetails respondsTo: #at:ifAbsent:) ifFalse: [ promptDetails := Dictionary new ].
	^ {
		'input_tokens' -> (self usageValueAt: 'prompt_tokens' in: usage).
		'output_tokens' -> (self usageValueAt: 'completion_tokens' in: usage).
		'cache_creation_input_tokens' -> 0.
		'cache_read_input_tokens' -> (self usageValueAt: 'cached_tokens' in: promptDetails) }
		asDictionary
]

{ #category : 'accessing' }
AgentOpenAITransport >> defaultModel [
	^ 'gpt-5.6'
]

{ #category : 'inference' }
AgentOpenAITransport >> exchangeFor: aCanonicalRequest apiKey: apiKey [
	| payload rawResponse |
	payload := self requestPayloadFor: aCanonicalRequest.
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

{ #category : 'translation' }
AgentOpenAITransport >> functionToolDefinitionsFor: tools [
	^ tools collect: [ :tool |
		{
			'type' -> 'function'.
			'function' -> ({
				'name' -> (tool at: 'name').
				'description' -> (tool at: 'description').
				'parameters' -> (tool at: 'input_schema') } asDictionary) }
			asDictionary ]
]

{ #category : 'translation' }
AgentOpenAITransport >> openAIAssistantMessageFrom: content [
	| text toolCalls message |
	(content isArray or: [ content isKindOf: OrderedCollection ]) ifFalse: [
		^ self malformedResponse: 'assistant content must be an array' ].
	text := String streamContents: [ :stream |
		content do: [ :block |
			(block at: 'type') = 'text' ifTrue: [
				stream nextPutAll: (block at: 'text') ] ] ].
	toolCalls := content
		select: [ :block | (block at: 'type') = 'tool_use' ]
		thenCollect: [ :block | self openAIToolCallFrom: block ].
	message := {
		'role' -> 'assistant'.
		'content' -> (text isEmpty ifTrue: [ nil ] ifFalse: [ text ]) }
		asDictionary.
	toolCalls isEmpty ifFalse: [ message at: 'tool_calls' put: toolCalls asArray ].
	^ message
]

{ #category : 'translation' }
AgentOpenAITransport >> openAIMessagesForStableInstructions: stableInstructions dynamicInstructions: dynamicInstructions canonicalMessages: canonicalMessages [
	| translated |
	translated := OrderedCollection new.
	translated add: ({
		'role' -> 'system'.
		'content' -> (stableInstructions , dynamicInstructions) } asDictionary).
	canonicalMessages do: [ :message |
		self addCanonicalMessage: message to: translated ].
	^ translated asArray
]

{ #category : 'translation' }
AgentOpenAITransport >> openAIToolCallFrom: toolUse [
	^ {
		'id' -> (toolUse at: 'id').
		'type' -> 'function'.
		'function' -> ({
			'name' -> (toolUse at: 'name').
			'arguments' -> (STONJSON toString: (toolUse at: 'input')) } asDictionary) }
		asDictionary
]

{ #category : 'translation' }
AgentOpenAITransport >> openAIToolResultFrom: toolResult [
	(toolResult respondsTo: #at:ifAbsent:) ifFalse: [
		^ self malformedResponse: 'tool result must be an object' ].
	^ {
		'role' -> 'tool'.
		'tool_call_id' -> (toolResult at: 'tool_use_id' ifAbsent: [
			self malformedResponse: 'tool result has no tool_use_id' ]).
		'content' -> (toolResult at: 'content' ifAbsent: [
			self malformedResponse: 'tool result has no content' ]) }
		asDictionary
]

{ #category : 'posting' }
AgentOpenAITransport >> postPayload: payload apiKey: apiKey timeoutSeconds: timeoutSeconds [
	^ self
		postJSONPayload: payload
		to: 'https://api.openai.com/v1/chat/completions'
		headers: ({ 'Authorization' -> ('Bearer ' , apiKey) } asDictionary)
		timeoutSeconds: timeoutSeconds
]

{ #category : 'accessing' }
AgentOpenAITransport >> providerName [
	^ 'openai-chat-completions'
]

{ #category : 'translation' }
AgentOpenAITransport >> requestPayloadFor: aCanonicalRequest [
	| system tools payload |
	system := aCanonicalRequest at: 'system'.
	tools := aCanonicalRequest at: 'tools'.
	payload := {
		'model' -> (aCanonicalRequest at: 'model').
		'max_completion_tokens' -> (aCanonicalRequest at: 'max_output_tokens').
		'messages' -> (self
			openAIMessagesForStableInstructions: (system at: 'stable')
			dynamicInstructions: (system at: 'dynamic')
			canonicalMessages: (aCanonicalRequest at: 'messages')) }
		asDictionary.
	tools ifNotNil: [
		payload
			at: 'tools' put: (self functionToolDefinitionsFor: tools);
			at: 'tool_choice' put: 'auto' ].
	^ payload
]

{ #category : 'prompt caching' }
AgentOpenAITransport >> revisionFor: source [
	^ 'characters-' , source size printString , '-hash-' , source hash printString
]
