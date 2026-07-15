"Paid evaluation for tool-first persistent facts. One request resolves a
natural reference through an exact lookup; another discovers all stored facts
through bounded browsing. Neither may fall back to Smalltalk evaluation."
| exactGateway broadGateway gateways exactAnswer broadAnswer
exactUsedKnowledge exactUsedGetFact exactUsedEvaluation exactAnswered
broadUsedKnowledge broadUsedList broadUsedEvaluation broadAnswered
passed failure started |
started := Time millisecondClockValue.
passed := false.
failure := nil.
exactGateway := AgentGateway new.
broadGateway := AgentGateway new.
gateways := { exactGateway. broadGateway }.
exactAnswer := ''.
broadAnswer := ''.
exactUsedKnowledge := false.
exactUsedGetFact := false.
exactUsedEvaluation := false.
exactAnswered := false.
broadUsedKnowledge := false.
broadUsedList := false.
broadUsedEvaluation := false.
broadAnswered := false.
[
	AgentCanvas reset.
	AgentFact key: #city body: 'Ushuaia'.
	AgentFact key: #timezone body: 'America/Sao_Paulo'.
	AgentFact body: 'prefers espresso after lunch'.

	Stdio stdout nextPutAll: '--- natural fact reference ---'; lf.
	exactAnswer := [
		exactGateway run: 'What city do I live in? Reply with just the city.' ]
		on: Error do: [ :error | failure := error messageText. '' ].
	Stdio stdout nextPutAll: exactAnswer; lf.
	exactUsedKnowledge := exactGateway log anySatisfy: [ :line |
		line beginsWith: 'KNOWLEDGE? ' ].
	exactUsedGetFact := exactGateway log anySatisfy: [ :line |
		(line beginsWith: 'KNOWLEDGE? ')
			and: [ line includesSubstring: 'get_fact' ] ].
	exactUsedEvaluation := exactGateway log anySatisfy: [ :line |
		line beginsWith: '>>> ' ].
	exactAnswered := exactAnswer asLowercase includesSubstring: 'ushuaia'.

	Stdio stdout nextPutAll: '--- broad fact discovery ---'; lf.
	broadAnswer := [
		broadGateway run:
			'What facts do you remember about me? Mention every stored fact.' ]
		on: Error do: [ :error | failure := error messageText. '' ].
	Stdio stdout nextPutAll: broadAnswer; lf.
	broadUsedKnowledge := broadGateway log anySatisfy: [ :line |
		line beginsWith: 'KNOWLEDGE? ' ].
	broadUsedList := broadGateway log anySatisfy: [ :line |
		(line beginsWith: 'KNOWLEDGE? ')
			and: [ line includesSubstring: 'list_facts' ] ].
	broadUsedEvaluation := broadGateway log anySatisfy: [ :line |
		line beginsWith: '>>> ' ].
	broadAnswered := (broadAnswer asLowercase includesSubstring: 'ushuaia')
		and: [ (broadAnswer includesSubstring: 'America/Sao_Paulo')
		and: [ broadAnswer asLowercase includesSubstring: 'espresso' ] ].

	passed := failure isNil
		and: [ exactUsedKnowledge
		and: [ exactUsedGetFact
		and: [ exactUsedEvaluation not
		and: [ exactAnswered
		and: [ broadUsedKnowledge
		and: [ broadUsedList
		and: [ broadUsedEvaluation not
		and: [ broadAnswered ] ] ] ] ] ] ] ] ]
	ensure: [
		AgentEvaluation
			reportNamed: 'fact-retrieval'
			gateways: gateways
			startedAt: started
			passed: passed
			details: {
				'exact_used_knowledge' -> exactUsedKnowledge.
				'exact_used_get_fact' -> exactUsedGetFact.
				'exact_used_evaluation' -> exactUsedEvaluation.
				'exact_answered' -> exactAnswered.
				'broad_used_knowledge' -> broadUsedKnowledge.
				'broad_used_list_facts' -> broadUsedList.
				'broad_used_evaluation' -> broadUsedEvaluation.
				'broad_answered_all' -> broadAnswered.
				'failure' -> (failure ifNil: [ '' ]) } asDictionary ].

Stdio stdout nextPutAll: '=== CHECKS ==='; lf.
Stdio stdout nextPutAll: 'natural reference used get_fact: '
	, exactUsedGetFact printString; lf.
Stdio stdout nextPutAll: 'natural reference answered stored city: '
	, exactAnswered printString; lf.
Stdio stdout nextPutAll: 'broad request used list_facts: '
	, broadUsedList printString; lf.
Stdio stdout nextPutAll: 'broad request answered every fact: '
	, broadAnswered printString; lf.
Stdio stdout nextPutAll: 'Smalltalk evaluation avoided: '
	, (exactUsedEvaluation not and: [ broadUsedEvaluation not ]) printString; lf.
Stdio stdout nextPutAll: (passed
	ifTrue: [ 'FACT RETRIEVAL SMOKE OK' ]
	ifFalse: [ 'FACT RETRIEVAL SMOKE FAILED' ]); lf.
passed ifTrue: [ Smalltalk exitSuccess ] ifFalse: [ Smalltalk exitFailure ]
