"Focused headless smoke for fact-first widget creation. One paid model request.
The request states #city and refers to it indirectly in the SAME turn. Passes
only if the fact is stored as a bare value and the new widget reads and reacts
to that fact rather than copying a literal or reusing an earlier city."
| answer fact widgets factBacked nonblocking noUpdateFailure weatherTool passed |
AgentCanvas reset.
Stdio stdout nextPutAll: '--- same-request fact-backed widget ---'; lf.
answer := [
	AgentGateway ask:
		'I live in Balneario Camboriu. Make a weather widget for the city I live in.' ]
	on: Error
	do: [ :e |
		Stdio stdout nextPutAll: 'FAILED: ' , e messageText; lf.
		Smalltalk exitFailure ].
Stdio stdout nextPutAll: answer; lf.

fact := AgentCanvas current factWithKey: #city.
widgets := AgentCanvas current contextWidgets.
factBacked := widgets anySatisfy: [ :w |
	(w class methods anySatisfy: [ :m |
		m sourceCode includesSubstring: 'AgentKnowledge' ])
		and: [ w class methods anySatisfy: [ :m |
			m sourceCode includesSubstring: 'AgentFactChanged' ] ] ].
nonblocking := widgets anySatisfy: [ :w |
	| initializeSource |
	initializeSource := (w class >> #initialize) sourceCode.
	(initializeSource includesSubstring: 'refreshAsync')
		and: [ w class methods anySatisfy: [ :m |
			(m sourceCode includesSubstring: 'forkNamed:')
				and: [ (m sourceCode includesSubstring: 'agent-widget-')
				and: [ (m sourceCode includesSubstring: 'runOnUiThreadSafely:')
				and: [ w class methods anySatisfy: [ :textMethod |
					textMethod sourceCode includesSubstring: 'setText:' ] ] ] ] ] ] ].
weatherTool := AgentTool tools anySatisfy: [ :tool |
	(tool name asLowercase includesSubstring: 'weather')
		or: [ (tool purpose ifNil: [ '' ]) asLowercase includesSubstring: 'weather' ] ].
noUpdateFailure := AgentCanvas current systemMessages noneSatisfy: [ :message |
	message body includesSubstring: 'Widget update failed' ].
passed := fact notNil
	and: [ fact body trimBoth = 'Balneario Camboriu'
	and: [ widgets notEmpty
	and: [ factBacked
	and: [ nonblocking
	and: [ weatherTool
	and: [ noUpdateFailure ] ] ] ] ] ].

Stdio stdout nextPutAll: 'city fact: '
	, (fact ifNil: [ 'MISSING' ] ifNotNil: [ :f | f describe ]); lf.
Stdio stdout nextPutAll: 'application widgets: ' , widgets size printString; lf.
Stdio stdout nextPutAll: 'widget reads and reacts to #city: ' , factBacked printString; lf.
Stdio stdout nextPutAll: 'widget construction is nonblocking: ' , nonblocking printString; lf.
Stdio stdout nextPutAll: 'reusable weather tool exists: ' , weatherTool printString; lf.
Stdio stdout nextPutAll: 'no asynchronous update failure: ' , noUpdateFailure printString; lf.
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'FACT-BACKED WIDGET OK' ]
	ifFalse: [ 'FACT-BACKED WIDGET FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
