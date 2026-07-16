"Explicit paid cache evidence. The provider may already hold the stable prefix,
so the first probe records observed cold-or-warm usage; the immediate follow-up
must read the same prefix from cache. This script is never part of verify-all."
| prompt cold warm coldAnswer warmAnswer coldStarted coldEnded warmStarted warmEnded coldLatency warmLatency coldUsage warmUsage coldSemantic warmSemantic coldDetails warmDetails passed failure |
prompt := 'What is 23 plus 19? Answer in one short sentence with the number. Do not use tools or create a widget.' .
cold := AgentGateway new.
warm := AgentGateway new.
coldAnswer := ''.
warmAnswer := ''.
coldUsage := Dictionary new.
warmUsage := Dictionary new.
coldSemantic := false.
warmSemantic := false.
coldLatency := 0.
warmLatency := 0.
passed := false.
failure := nil.
[
	AgentCanvas reset.
	Stdio stdout nextPutAll: '--- stable-prefix cache cold probe ---'; lf.
	coldStarted := Time millisecondClockValue.
	coldAnswer := [ cold run: prompt ]
		on: Error do: [ :error | failure := error messageText. '' ].
	coldEnded := Time millisecondClockValue.
	coldLatency := coldEnded - coldStarted.
	coldLatency < 0 ifTrue: [ coldLatency := coldLatency + 4294967296 ].
	coldUsage := cold usageTotals.
	coldSemantic := coldAnswer includesSubstring: '42'.

	"Keep the dynamic suffix identical without reusing any canvas state."
	AgentCanvas reset.
	Stdio stdout nextPutAll: '--- stable-prefix cache warm probe ---'; lf.
	warmStarted := Time millisecondClockValue.
	warmAnswer := [ warm run: prompt ]
		on: Error do: [ :error | failure := failure ifNil: [ error messageText ]. '' ].
	warmEnded := Time millisecondClockValue.
	warmLatency := warmEnded - warmStarted.
	warmLatency < 0 ifTrue: [ warmLatency := warmLatency + 4294967296 ].
	warmUsage := warm usageTotals.
	warmSemantic := warmAnswer includesSubstring: '42'.
	coldDetails := {
		'latency_ms' -> coldLatency.
		'rounds' -> cold requestCount.
		'repairs' -> cold repairAttempts.
		'usage' -> coldUsage.
		'cache' -> (cold requestMetrics at: 'cache').
		'cache_write_tokens' -> (coldUsage at: 'cache_creation_input_tokens').
		'cache_read_tokens' -> (coldUsage at: 'cache_read_input_tokens').
		'cost' -> ({
			'currency' -> 'USD'.
			'amount' -> nil.
			'source' -> 'not returned by the provider; exact token usage recorded' } asDictionary).
		'semantic_outcome' -> coldSemantic } asDictionary.
	warmDetails := {
		'latency_ms' -> warmLatency.
		'rounds' -> warm requestCount.
		'repairs' -> warm repairAttempts.
		'usage' -> warmUsage.
		'cache' -> (warm requestMetrics at: 'cache').
		'cache_write_tokens' -> (warmUsage at: 'cache_creation_input_tokens').
		'cache_read_tokens' -> (warmUsage at: 'cache_read_input_tokens').
		'cost' -> ({
			'currency' -> 'USD'.
			'amount' -> nil.
			'source' -> 'not returned by the provider; exact token usage recorded' } asDictionary).
		'semantic_outcome' -> warmSemantic } asDictionary.
	passed := failure isNil
		and: [ coldSemantic
			and: [ warmSemantic
				and: [ (warmUsage at: 'cache_read_input_tokens') > 0 ] ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'prompt-cache'
			gateways: { cold. warm }
			startedAt: (coldStarted ifNil: [ Time millisecondClockValue ])
			passed: passed
			details: ({
				'prompt' -> prompt.
				'cold' -> (coldDetails ifNil: [ Dictionary new ]).
				'warm' -> (warmDetails ifNil: [ Dictionary new ]).
				'failure' -> (failure ifNil: [ '' ]) } asDictionary) ].

Stdio stdout nextPutAll: 'cold answer: ' , coldAnswer; lf.
Stdio stdout nextPutAll: 'warm answer: ' , warmAnswer; lf.
Stdio stdout nextPutAll: 'cold cache write/read tokens: '
	, (coldUsage at: 'cache_creation_input_tokens') printString , '/'
	, (coldUsage at: 'cache_read_input_tokens') printString; lf.
Stdio stdout nextPutAll: 'warm cache write/read tokens: '
	, (warmUsage at: 'cache_creation_input_tokens') printString , '/'
	, (warmUsage at: 'cache_read_input_tokens') printString; lf.
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'PROMPT CACHE OK' ]
	ifFalse: [ 'PROMPT CACHE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
