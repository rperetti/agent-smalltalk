"
I am the bridge between the live image and the Anthropic Messages API.
I run the agentic tool-use loop: the model calls the evaluate_smalltalk tool,
I evaluate the code via AgentSandbox and feed the result (or error report) back,
and the model iterates until it succeeds or the tool-round cap is reached. At
the cap, one tools-disabled response consumes and reports the final tool result.
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
		'statusBlock',
		'transport',
		'reportedAsyncFailureCounts',
		'requestCount',
		'usageTotals',
		'previousToolFailed',
		'repairAttempts'
	],
	#classInstVars : [
		'last',
		'runMutex'
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

{ #category : 'running' }
AgentGateway class >> runMutex [
	"One writer for the living image. Multiple UI submissions or
	programmatic asks may wait, but their tool calls never interleave."
	^ runMutex ifNil: [ runMutex := Semaphore forMutualExclusion ]
]

{ #category : 'system startup' }
AgentGateway class >> resetRunMutex [
	"A mutex may have been serialized while owned by a process that does not
	survive the snapshot. Every fresh session starts with an unlocked writer."
	runMutex := Semaphore forMutualExclusion
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
AgentGateway class >> basePromptFile [
	"prompts/system.md at the repository root (the image lives in <repo>/pharo/)."
	^ FileLocator image asFileReference parent parent / 'prompts' / 'system.md'
]

{ #category : 'accessing' }
AgentGateway class >> basePrompt [
	| file |
	file := self basePromptFile.
	^ file exists
		ifTrue: [ file contents ]
		ifFalse: [ self error: 'Base prompt not found at ' , file fullName ]
]

{ #category : 'initialization' }
AgentGateway >> initialize [
	super initialize.
	model := 'claude-sonnet-5'.
	maxRounds := 30.
	sandbox := AgentSandbox new.
	log := OrderedCollection new.
	statusBlock := [ :msg |  ].
	transport := AgentAnthropicTransport new.
	reportedAsyncFailureCounts := Dictionary new.
	self resetEvaluationMetrics
]

{ #category : 'evaluation metrics' }
AgentGateway >> resetEvaluationMetrics [
	"A gateway can be reused programmatically. Metrics describe its current run,
	not stale failures or token usage from an earlier request."
	requestCount := 0.
	usageTotals := Dictionary new.
	#(input_tokens output_tokens cache_creation_input_tokens cache_read_input_tokens)
		do: [ :key | usageTotals at: key put: 0 ].
	previousToolFailed := false.
	repairAttempts := 0
]

{ #category : 'accessing' }
AgentGateway >> apiKey [
	^ apiKey ifNil: [
		apiKey := Smalltalk os environment
			at: 'ANTHROPIC_API_KEY'
			ifAbsent: [ self error: 'ANTHROPIC_API_KEY is not set in the environment' ] ]
]

{ #category : 'accessing' }
AgentGateway >> apiKey: aString [
	"Injection point for deterministic tests; production reads the environment."
	apiKey := aString
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

{ #category : 'accessing' }
AgentGateway >> transport [
	^ transport
]

{ #category : 'accessing' }
AgentGateway >> transport: aTransport [
	transport := aTransport
]

{ #category : 'evaluation metrics' }
AgentGateway >> requestCount [
	^ requestCount ifNil: [ 0 ]
]

{ #category : 'evaluation metrics' }
AgentGateway >> repairAttempts [
	^ repairAttempts ifNil: [ 0 ]
]

{ #category : 'evaluation metrics' }
AgentGateway >> usageTotals [
	^ (usageTotals ifNil: [ Dictionary new ]) copy
]

{ #category : 'running' }
AgentGateway >> run: userText [
	^ self class runMutex critical: [ self runUnlocked: userText ]
]

{ #category : 'running' }
AgentGateway >> runUnlocked: userText [
	| messages widgetsBefore finalToolResults |
	self resetEvaluationMetrics.
	self class noteLast: self.
	self logAdd: '===== USER REQUEST: ' , userText.
	self status: 'thinking...'.
	sandbox backupImage.
	messages := OrderedCollection with:
		{ 'role' -> 'user'. 'content' -> userText } asDictionary.
	widgetsBefore := self canvasWidgetsSnapshot.
	finalToolResults := #().
	1 to: maxRounds do: [ :round |
		| response content toolUses |
		response := self post: messages.
		content := response at: 'content'.
		messages add: { 'role' -> 'assistant'. 'content' -> content } asDictionary.
		toolUses := content select: [ :block | (block at: 'type') = 'tool_use' ].
		toolUses isEmpty ifTrue: [
			^ self noteIfPureAnswer: (self finalTextFrom: content)
				for: userText
				since: widgetsBefore ].
		self status: (round = 1
			ifTrue: [ 'evaluating...' ]
			ifFalse: [ 'working (round ' , round printString , ' of ' , maxRounds printString , ')...' ]).
		finalToolResults := toolUses collect: [ :tu |
			self runTool: tu forUserRequest: userText ].
		messages add: { 'role' -> 'user'.
			'content' -> (self
				appendBudgetNoteTo: finalToolResults asArray
				afterRound: round) } asDictionary ].
	^ self
		finishAfterRoundCapWith: messages
		for: userText
		since: widgetsBefore
		lastToolResults: finalToolResults
]

{ #category : 'running' }
AgentGateway >> finishAfterRoundCapWith: messages for: userText since: widgetsBefore lastToolResults: toolResults [
	"The tool budget and the inference budget are deliberately separate. Once
	the final permitted mutation has run, give the model one tools-disabled
	response in which to consume its result and report the outcome."
	| response content answer |
	self status: 'finishing...'.
	[ response := self post: messages includeTools: false ]
		on: Error
		do: [ :error |
			^ self
				noteIfPureAnswer: (self finalRoundFallbackFor: toolResults
					because: error messageText)
				for: userText
				since: widgetsBefore ].
	content := response at: 'content' ifAbsent: [ #() ].
	messages add: { 'role' -> 'assistant'. 'content' -> content } asDictionary.
	answer := self finalTextFrom: content.
	answer trimBoth isEmpty ifTrue: [
		^ self
			noteIfPureAnswer: (self finalRoundFallbackFor: toolResults
				because: 'the finishing response contained no text')
			for: userText
			since: widgetsBefore ].
	^ self noteIfPureAnswer: answer for: userText since: widgetsBefore
]

{ #category : 'running' }
AgentGateway >> finalRoundFallbackFor: toolResults because: reason [
	"Never hide the outcome of a tool call that already ran just because the
	tools-disabled finishing inference failed or returned malformed content."
	^ String streamContents: [ :stream |
		stream
			<< 'The tool-round budget was exhausted after the final tool execution. ';
			<< 'A final model response was unavailable because ';
			<< reason;
			<< '. The final tool result(s) were:'.
		toolResults do: [ :result |
			stream cr; << (result at: 'content' ifAbsent: [ '<missing result>' ]) ] ]
]

{ #category : 'running' }
AgentGateway >> runTool: aToolUse [
	^ self runTool: aToolUse forUserRequest: nil
]

{ #category : 'running' }
AgentGateway >> runTool: aToolUse forUserRequest: userText [
	| name input result |
	previousToolFailed == true ifTrue: [ repairAttempts := self repairAttempts + 1 ].
	name := aToolUse at: 'name' ifAbsent: [ 'evaluate_smalltalk' ].
	input := aToolUse at: 'input' ifAbsent: [ Dictionary new ].
	name = 'evaluate_smalltalk'
		ifTrue: [
			| code factError |
			code := input at: 'code' ifAbsent: [ '' ].
			self logAdd: '>>> ' , code.
			factError := self factMutationErrorIn: code forUserRequest: userText.
			result := factError
				ifNil: [ sandbox evaluate: code ]
				ifNotNil: [ factError ] ]
		ifFalse: [
			name = 'search_image'
				ifTrue: [
					self logAdd: '??? ' , (STONJSON toString: input).
					result := AgentImageSearch handle: input ]
					ifFalse: [ result := 'ERROR: unknown tool ' , name ] ].
	self logAdd: result.
	previousToolFailed := result beginsWith: 'ERROR:'.
	result := self appendPendingAsyncFailuresTo: result.
	^ { 'type' -> 'tool_result'.
		'tool_use_id' -> (aToolUse at: 'id').
		'content' -> result } asDictionary
]

{ #category : 'fact authorization' }
AgentGateway >> factMutationErrorIn: code forUserRequest: userText [
	"Fact writes made by model tool calls require a literal value that appeared
	in this request. This stops a widget-building request from replacing a
	known fact with a model-invented default, while preserving implicit capture
	of facts the user actually stated. Direct/operator evaluation passes nil and
	is deliberately outside this gateway-specific authority boundary."
	| values |
	userText ifNil: [ ^ nil ].
	values := self factMutationValuesIn: code.
	values ifNil: [
		^ 'ERROR: fact write rejected: use a literal value explicitly supplied by the user, or do not write a fact. Read existing facts through AgentKnowledge while building a widget.' ].
	values do: [ :value |
		((userText asLowercase includesSubstring: value asLowercase)
			and: [ value isEmpty not ]) ifFalse: [
			^ 'ERROR: fact write rejected: ''' , value
				, ''' was not supplied in this request. Read the known fact through AgentKnowledge; do not replace it while building a widget.' ] ].
	^ nil
]

{ #category : 'fact authorization' }
AgentGateway >> factMutationValuesIn: code [
	"Answer decoded literal values passed to direct AgentFact writes. Nil means
	the source contains a Fact reference that cannot be proven to be one of the
	allowed class-side writes, or a body that is not one bare string literal."
	| tree values factReferences factWrites |
	[ tree := RBParser parseExpression: code.
		values := OrderedCollection new.
		factReferences := tree allChildren select: [ :node |
			node isVariable and: [ node name = #AgentFact ] ].
		factWrites := tree allChildren select: [ :node |
			self isDirectFactMutationNode: node ].
		"Every AgentFact reference must belong to one direct write. This rejects
		indirect sends such as AgentFact new body: ... and perform: ... before
		the sandbox can evaluate them."
		factReferences size = factWrites size ifFalse: [ ^ nil ].
		factWrites do: [ :write |
			| bodyNode literalSource |
			bodyNode := self factBodyNodeIn: write.
			(bodyNode isLiteralNode and: [ bodyNode value isKindOf: String ])
				ifFalse: [ ^ nil ].
			literalSource := (code
				copyFrom: bodyNode start
				to: bodyNode stop) trimBoth.
			"The AST preserves the source interval. Requiring quote delimiters
				there rejects even a parenthesized literal, while value answers
				the fully decoded Smalltalk string for authorization."
			(literalSource size >= 2 and: [
				literalSource first = $' and: [ literalSource last = $' ] ])
				ifFalse: [ ^ nil ].
			values add: bodyNode value ].
		^ values ]
		on: Error
		do: [ :error | nil ]
]

{ #category : 'fact authorization' }
AgentGateway >> isDirectFactMutationNode: aNode [
	| selector receiver |
	aNode isMessage ifFalse: [ ^ false ].
	selector := aNode selector.
	(selector = #body: or: [ selector = #key:body: ]) ifFalse: [ ^ false ].
	receiver := aNode receiver.
	^ receiver isVariable and: [ receiver name = #AgentFact ]
]

{ #category : 'fact authorization' }
AgentGateway >> factBodyNodeIn: aFactWrite [
	^ aFactWrite selector = #body:
		ifTrue: [ aFactWrite arguments first ]
		ifFalse: [ aFactWrite arguments second ]
]

{ #category : 'running' }
AgentGateway >> appendPendingAsyncFailuresTo: result [
	| failures |
	failures := self pendingAsyncFailures.
	failures isEmpty ifTrue: [ ^ result ].
	^ String streamContents: [ :s |
		s << result.
		s cr.
		s << '[system: asynchronous widget update failure(s) occurred. '
			<< 'Fix and re-verify the live widget before finishing.]'.
		s cr.
		failures do: [ :message |
			s << '- ' << message body.
			s cr ] ]
]

{ #category : 'running' }
AgentGateway >> pendingAsyncFailures [
	| canvasClass failures |
	reportedAsyncFailureCounts ifNil: [
		reportedAsyncFailureCounts := Dictionary new ].
	canvasClass := Smalltalk globals at: #AgentCanvas ifAbsent: [ ^ #() ].
	failures := OrderedCollection new.
	canvasClass current systemMessages do: [ :message |
		| key previousCount |
		key := message key.
		(key notNil and: [
			key asString beginsWith: 'widgetUpdateFailure-' ]) ifTrue: [
				previousCount := reportedAsyncFailureCounts
					at: key
					ifAbsent: [ 0 ].
				message count > previousCount ifTrue: [
					reportedAsyncFailureCounts at: key put: message count.
					failures add: message ] ] ].
	^ failures
]

{ #category : 'running' }
AgentGateway >> post: messages [
	^ self post: messages includeTools: true
]

{ #category : 'running' }
AgentGateway >> post: messages includeTools: includeTools [
	| payload response |
	payload := {
		'model' -> model.
		'max_tokens' -> 8192.
		'system' -> self systemPrompt.
		'messages' -> messages asArray } asDictionary.
	includeTools ifTrue: [ payload at: 'tools' put: self toolDefinitions ].
	self logAdd: 'HTTP REQUEST: ' , (STONJSON toString: payload).
	[ response := transport postPayload: payload apiKey: self apiKey ]
		on: Error
			do: [ :error |
				self logAdd: 'HTTP ERROR: ' , error messageText.
				error pass ].
	requestCount := self requestCount + 1.
	self recordUsageFrom: response.
	self logAdd: 'HTTP RESPONSE: ' , (STONJSON toString: response).
	^ response
]

{ #category : 'evaluation metrics' }
AgentGateway >> recordUsageFrom: response [
	"Messages API responses report token usage but not the billed dollar amount.
	Keep exact usage totals so provider evaluations can record evidence without
	pretending to know a price that was not returned by the API."
	| usage |
	usage := response at: 'usage' ifAbsent: [ ^ self ].
	usageTotals ifNil: [ usageTotals := Dictionary new ].
	#(input_tokens output_tokens cache_creation_input_tokens cache_read_input_tokens)
		do: [ :key |
			| value |
			value := usage at: key ifAbsent: [ 0 ].
			usageTotals
				at: key
				put: (usageTotals at: key ifAbsent: [ 0 ]) + value ]
]

{ #category : 'running' }
AgentGateway >> canvasWidgetsSnapshot [
	^ (Smalltalk globals at: #AgentCanvas ifAbsent: [ nil ])
		ifNil: [ 0 ]
		ifNotNil: [ :cls | cls current widgetAddVersion ]
]

{ #category : 'running' }
AgentGateway >> noteIfPureAnswer: answer for: userText since: widgetsBefore [
	"The heuristic: if the run produced no widget, the text IS the
	deliverable -- put it on an AgentNote so it lives on the canvas.
	If the model already made a note (or any widget), skip: the canvas
	speaks for itself. Always answers the text unchanged."
	| canvasClass noteClass |
	canvasClass := Smalltalk globals at: #AgentCanvas ifAbsent: [ ^ answer ].
	noteClass := Smalltalk globals at: #AgentNote ifAbsent: [ ^ answer ].
	answer trimBoth isEmpty ifTrue: [ ^ answer ].
	canvasClass current widgetAddVersion = widgetsBefore ifTrue: [
		[ noteClass question: userText answer: answer ]
			on: Error
			do: [ :e |
				self logAdd: 'note creation failed: ' , e messageText.
				(Smalltalk globals at: #AgentSystemMessage ifAbsent: [ nil ])
					ifNotNil: [ :msgClass |
						[ msgClass post: 'Failed to create an answer note: ' , e messageText
							key: #noteFailure ] on: Error do: [ :e2 |  ] ] ] ].
	^ answer
]

{ #category : 'running' }
AgentGateway >> appendBudgetNoteTo: toolResults afterRound: round [
	"When the round budget is nearly spent, tell the model so it ships
	instead of polishing. Appended to the last tool result's content."
	| remaining last |
	remaining := maxRounds - round.
	remaining = 0 ifTrue: [
		last := toolResults last.
		last at: 'content' put: ((last at: 'content') , String cr
			, '[system: the tool-round budget is exhausted. No more tools are available. '
			, 'Give a final response now and report the tool result accurately.]').
		^ toolResults ].
	(remaining between: 1 and: 3) ifFalse: [ ^ toolResults ].
	last := toolResults last.
	last at: 'content' put: ((last at: 'content') , String cr
		, '[system: only ' , remaining printString
		, ' tool round(s) remain. Finish now: summon the widget and give your final answer; skip polish.]').
	^ toolResults
]

{ #category : 'running' }
AgentGateway >> toolDefinitions [
	^ { self evaluateToolDefinition. self searchToolDefinition }
]

{ #category : 'running' }
AgentGateway >> searchToolDefinition [
	^ {
		'name' -> 'search_image'.
		'description' -> ('Cheaply explore the live image instead of writing reflection code. '
			, 'Actions: find_classes (query = class-name fragment), '
			, 'find_selectors (class_name, optional query = selector fragment; empty query lists own selectors), '
			, 'method_source (class_name, query = exact selector; use ''Foo class'' for class-side).').
		'input_schema' -> {
			'type' -> 'object'.
			'properties' -> {
				'action' -> {
					'type' -> 'string'.
					'enum' -> #('find_classes' 'find_selectors' 'method_source') } asDictionary.
				'query' -> { 'type' -> 'string' } asDictionary.
				'class_name' -> { 'type' -> 'string' } asDictionary } asDictionary.
			'required' -> #('action') } asDictionary } asDictionary
]

{ #category : 'running' }
AgentGateway >> evaluateToolDefinition [
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
	| base canvasClass dynamic capabilities automations |
	base := self class basePrompt.
	canvasClass := Smalltalk globals at: #AgentCanvas ifAbsent: [ nil ].
	dynamic := canvasClass
		ifNil: [ '' ]
		ifNotNil: [ :cls | String cr , cls current contextDescription ].
	capabilities := (Smalltalk globals at: #AgentTool ifAbsent: [ nil ])
		ifNil: [ '' ]
		ifNotNil: [ :cls | String cr , String cr , cls contextListing ].
	automations := (Smalltalk globals at: #AgentAutomation ifAbsent: [ nil ])
		ifNil: [ '' ]
		ifNotNil: [ :cls | String cr , String cr , cls contextListing ].
	^ base , dynamic , capabilities , automations
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
