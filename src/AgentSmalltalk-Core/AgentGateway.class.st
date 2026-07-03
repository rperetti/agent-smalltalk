"
I am the bridge between the live image and the Anthropic Messages API.
I run the agentic tool-use loop: the model calls the evaluate_smalltalk tool,
I evaluate the code via AgentSandbox and feed the result (or error report) back,
and the model iterates until it succeeds or the round cap is reached.
"
Class {
	#name : 'AgentGateway',
	#superclass : 'Object',
	#instVars : [
		'apiKey',
		'model',
		'maxRounds',
		'sandbox',
		'log',
		'statusBlock'
	],
	#classInstVars : [
		'last'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'convenience' }
AgentGateway class >> ask: aString [
	"Entry point: AgentGateway ask: 'make me a counter widget'."
	^ self new run: aString
]

{ #category : 'accessing' }
AgentGateway class >> last [
	"The most recently run gateway, for post-mortem inspection:
	AgentGateway last log."
	^ last
]

{ #category : 'accessing' }
AgentGateway class >> noteLast: aGateway [
	last := aGateway
]

{ #category : 'accessing' }
AgentGateway class >> logFile [
	"Append-only transcript of every request: loop events plus full HTTP
	request/response JSON payloads. The API key lives in headers and is
	never written here."
	| dir |
	dir := FileLocator image asFileReference parent parent / 'logs'.
	dir ensureCreateDirectory.
	^ dir / 'gateway.log'
]

{ #category : 'accessing' }
AgentGateway class >> cribSheetFile [
	"prompts/system.md at the repository root (the image lives in <repo>/pharo/)."
	^ FileLocator image asFileReference parent parent / 'prompts' / 'system.md'
]

{ #category : 'accessing' }
AgentGateway class >> cribSheet [
	| file |
	file := self cribSheetFile.
	^ file exists
		ifTrue: [ file contents ]
		ifFalse: [ self error: 'Crib sheet not found at ' , file fullName ]
]

{ #category : 'initialization' }
AgentGateway >> initialize [
	super initialize.
	model := 'claude-sonnet-5'.
	maxRounds := 8.
	sandbox := AgentSandbox new.
	log := OrderedCollection new.
	statusBlock := [ :msg |  ]
]

{ #category : 'accessing' }
AgentGateway >> apiKey [
	^ apiKey ifNil: [
		apiKey := Smalltalk os environment
			at: 'ANTHROPIC_API_KEY'
			ifAbsent: [ self error: 'ANTHROPIC_API_KEY is not set in the environment' ] ]
]

{ #category : 'accessing' }
AgentGateway >> model [
	^ model
]

{ #category : 'accessing' }
AgentGateway >> model: aString [
	model := aString
]

{ #category : 'accessing' }
AgentGateway >> maxRounds: anInteger [
	maxRounds := anInteger
]

{ #category : 'accessing' }
AgentGateway >> sandbox [
	^ sandbox
]

{ #category : 'accessing' }
AgentGateway >> log [
	^ log
]

{ #category : 'accessing' }
AgentGateway >> statusBlock: aBlock [
	statusBlock := aBlock
]

{ #category : 'running' }
AgentGateway >> run: userText [
	| messages |
	self class noteLast: self.
	self logAdd: '===== USER REQUEST: ' , userText.
	self status: 'thinking...'.
	sandbox backupImage.
	messages := OrderedCollection with:
		{ 'role' -> 'user'. 'content' -> userText } asDictionary.
	1 to: maxRounds do: [ :round |
		| response content toolUses |
		response := self post: messages.
		content := response at: 'content'.
		messages add: { 'role' -> 'assistant'. 'content' -> content } asDictionary.
		toolUses := content select: [ :block | (block at: 'type') = 'tool_use' ].
		toolUses isEmpty ifTrue: [ ^ self finalTextFrom: content ].
		self status: (round = 1
			ifTrue: [ 'evaluating...' ]
			ifFalse: [ 'repairing (round ' , round printString , ')...' ]).
		messages add: { 'role' -> 'user'.
			'content' -> ((toolUses collect: [ :tu | self runTool: tu ]) asArray) } asDictionary ].
	self error: 'Gave up after ' , maxRounds printString
		, ' tool rounds. Inspect the gateway log for the attempts.'
]

{ #category : 'running' }
AgentGateway >> runTool: aToolUse [
	| code result |
	code := (aToolUse at: 'input') at: 'code' ifAbsent: [ '' ].
	self logAdd: '>>> ' , code.
	result := sandbox evaluate: code.
	self logAdd: result.
	^ { 'type' -> 'tool_result'.
		'tool_use_id' -> (aToolUse at: 'id').
		'content' -> result } asDictionary
]

{ #category : 'running' }
AgentGateway >> post: messages [
	| payload client body |
	payload := {
		'model' -> model.
		'max_tokens' -> 8192.
		'system' -> self systemPrompt.
		'tools' -> (Array with: self toolDefinition).
		'messages' -> messages asArray } asDictionary.
	client := ZnClient new.
	self logAdd: 'HTTP REQUEST: ' , (STONJSON toString: payload).
	client
		url: 'https://api.anthropic.com/v1/messages';
		headerAt: 'x-api-key' put: self apiKey;
		headerAt: 'anthropic-version' put: '2023-06-01';
		entity: (ZnEntity with: (STONJSON toString: payload) type: ZnMimeType applicationJson);
		timeout: 180.
	body := client post.
	self logAdd: 'HTTP RESPONSE: ' , (body ifNil: [ '<no body>' ]).
	client isSuccess ifFalse: [
		self error: 'Anthropic API error: ' , client response statusLine printString
			, ' — ' , (body ifNil: [ '<no body>' ]) printString ].
	^ STONJSON fromString: body
]

{ #category : 'running' }
AgentGateway >> toolDefinition [
	^ {
		'name' -> 'evaluate_smalltalk'.
		'description' -> ('Evaluate raw Pharo Smalltalk source code in the live image. '
			, 'Answers ''RESULT: <printString of the value>'' on success or ''ERROR: <report>'' on failure. '
			, 'Image state (classes, methods, objects) persists between calls.').
		'input_schema' -> {
			'type' -> 'object'.
			'properties' -> {
				'code' -> {
					'type' -> 'string'.
					'description' -> 'Raw Pharo Smalltalk expression(s). No markdown, no backticks.' } asDictionary } asDictionary.
			'required' -> #('code') } asDictionary } asDictionary
]

{ #category : 'running' }
AgentGateway >> finalTextFrom: content [
	^ ((content select: [ :b | (b at: 'type') = 'text' ])
		collect: [ :b | b at: 'text' ])
		inject: '' into: [ :acc :each | acc , each ]
]

{ #category : 'running' }
AgentGateway >> systemPrompt [
	| crib canvasClass dynamic |
	crib := self class cribSheet.
	canvasClass := Smalltalk globals at: #AgentCanvas ifAbsent: [ nil ].
	dynamic := canvasClass
		ifNil: [ '' ]
		ifNotNil: [ :cls |
			String cr , '## Widgets currently on the canvas' , String cr
				, cls current contextDescription ].
	^ crib , dynamic
]

{ #category : 'private' }
AgentGateway >> status: aString [
	self logAdd: '[status] ' , aString.
	statusBlock value: aString
]

{ #category : 'private' }
AgentGateway >> logAdd: aString [
	log add: aString.
	[ | stream |
		stream := self class logFile writeStream.
		stream setToEnd.
		stream nextPutAll: DateAndTime now printString.
		stream nextPutAll: ' | '.
		stream nextPutAll: aString.
		stream lf.
		stream close ]
		on: Error
		do: [ :e | "logging must never break the loop" ]
]
