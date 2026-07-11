"
I record evidence for an explicitly paid provider evaluation. Deterministic
SUnit and local smoke gates stay separate from these records: a provider result
can be useful evidence without being treated as a reproducible release signal.
"
Class {
	#name : 'AgentEvaluation',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'recording' }
AgentEvaluation class >> reportNamed: aName gateways: gateways startedAt: startedMilliseconds passed: passed details: details [
	| report |
	report := self
		reportNamed: aName
		gateways: gateways
		startedAt: startedMilliseconds
		endedAt: Time millisecondClockValue
		passed: passed
		details: details.
	self append: report.
	Stdio stdout nextPutAll: 'EVALUATION_RECORD ' , (STONJSON toString: report); lf.
	^ report
]

{ #category : 'recording' }
AgentEvaluation class >> reportNamed: aName gateways: gateways startedAt: startedMilliseconds endedAt: endedMilliseconds passed: passed details: details [
	| allGateways elapsed usage models |
	allGateways := gateways asArray.
	elapsed := endedMilliseconds - startedMilliseconds.
	elapsed < 0 ifTrue: [ elapsed := elapsed + 4294967296 ].
	usage := self usageTotalsFor: allGateways.
	models := (allGateways collect: [ :gateway | gateway model ]) asSet asArray.
	^ {
		'evaluation' -> aName.
		'timestamp' -> DateAndTime now printString.
		'outcome' -> (passed ifTrue: [ 'passed' ] ifFalse: [ 'failed' ]).
		'models' -> models.
		'prompt_revision' -> self promptRevision.
		'rounds' -> (allGateways inject: 0 into: [ :total :gateway |
			total + gateway requestCount ]).
		'latency_ms' -> elapsed.
		'repairs' -> (allGateways inject: 0 into: [ :total :gateway |
			total + gateway repairAttempts ]).
		'usage' -> usage.
		'cost' -> {
			'currency' -> 'USD'.
			'amount' -> nil.
			'source' -> 'not returned by the provider; exact token usage recorded' } asDictionary.
		'details' -> details } asDictionary
]

{ #category : 'recording' }
AgentEvaluation class >> append: aReport [
	"Evidence must never turn a completed evaluation into an unreported crash.
	The JSON line on stdout remains available even if the local log is unwritable."
	[ | directory stream |
		directory := FileLocator image asFileReference parent parent / 'logs'.
		directory ensureCreateDirectory.
		stream := (directory / 'provider-evaluations.jsonl') writeStream.
		stream setToEnd.
		stream nextPutAll: (STONJSON toString: aReport); lf; close ]
		on: Error do: [ :ignored |  ]
]

{ #category : 'private' }
AgentEvaluation class >> promptRevision [
	| prompt |
	prompt := AgentGateway basePrompt.
	^ 'characters-' , prompt size printString , '-hash-' , prompt hash printString
]

{ #category : 'private' }
AgentEvaluation class >> usageTotalsFor: gateways [
	| totals |
	totals := Dictionary new.
	#(input_tokens output_tokens cache_creation_input_tokens cache_read_input_tokens)
		do: [ :key | totals at: key put: 0 ].
	gateways do: [ :gateway |
		gateway usageTotals keysAndValuesDo: [ :key :value |
			totals at: key put: (totals at: key ifAbsent: [ 0 ]) + value ] ].
	^ totals
]
