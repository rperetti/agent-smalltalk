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
