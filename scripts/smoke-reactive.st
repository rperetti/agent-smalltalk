"Headless acceptance for phase 4 (reactive canvas). Does NOT save the image.
Outcome-based assertions: the model may reuse/upgrade existing widgets, so we
check that state changes propagate, not that specific objects appear.
A) after a fact edit, SOME widget reflects the new city with NO request
B) after a counter bump, SOME non-counter widget's describe changes by itself"
| canvas answer counters cls beforeDescribes changed |
canvas := AgentCanvas current.
AgentFact key: #city body: 'Rodrigo lives in Tokyo'.

Stdio stdout nextPutAll: '--- A: reactive clock ---'; lf.
answer := [ AgentGateway ask: 'make sure there is a clock widget showing the current time in my city, staying correct if my city ever changes' ]
	on: Error do: [ :e | 'FAILED: ' , e messageText ].
Stdio stdout nextPutAll: answer; lf.
AgentFact key: #city body: 'Rodrigo lives in Reykjavik'.
Stdio stdout nextPutAll: ((canvas toolWidgets anySatisfy: [ :w |
		w describe asLowercase includesSubstring: 'reykjavik' ])
	ifTrue: [ 'REACTIVE FACT OK' ]
	ifFalse: [ 'NO WIDGET FOLLOWED THE FACT' ]); lf.

Stdio stdout nextPutAll: '--- B: live total ---'; lf.
cls := AgentWidget defineNamed: #ReactCounter slots: #(count).
cls compile: 'count ^ count ifNil: [0]'.
cls compile: 'bump count := self count + 1. self announceChanged'.
cls compile: 'describe ^ ''a counter at '' , self count printString'.
counters := (1 to: 3) collect: [ :i |
	| c |
	c := cls new.
	i timesRepeat: [ c bump ].
	canvas addWidget: c.
	c ].
canvas selectWidgets: counters.
answer := [ AgentGateway ask: 'make a live total of these selected counters - it must update by itself when any counter changes, no refresh button' ]
	on: Error do: [ :e | 'FAILED: ' , e messageText ].
Stdio stdout nextPutAll: answer; lf.
beforeDescribes := (canvas toolWidgets reject: [ :w | w isKindOf: cls ])
	collect: [ :w | w -> w describe ].
(Smalltalk globals at: #Selection1) bump.
changed := beforeDescribes select: [ :assoc | assoc key describe ~= assoc value ].
changed do: [ :assoc |
	Stdio stdout nextPutAll: 'changed by itself: ' , assoc key describe; lf ].
Stdio stdout nextPutAll: (changed
	ifEmpty: [ 'TOTAL DID NOT FOLLOW' ]
	ifNotEmpty: [ 'REACTIVE WIDGETS OK' ]); lf.
Smalltalk exitSuccess
