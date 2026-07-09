"Deterministic Phase 6 vertical smoke. No model call and no snapshot.
Exercises the exact generated-class API, first-run verification, due-run
deduplication, structured change notification, missed-run semantics, and
delete/undo registration."
| class now routine due card count passed |
passed := false.
[
	AgentScheduler reset.
	AgentAutomation resetRegistry.
	AgentCanvas reset.
	Smalltalk globals at: #AgentAutomationSmokeCount put: 0.

	class := AgentAutomation
		defineNamed: #AgentAutomationSmokeRoutine
		purpose: 'prove the scheduled automation vertical slice'.
	class compile: 'run
		| count |
		count := (Smalltalk globals
			at: #AgentAutomationSmokeCount
			ifAbsent: [ 0 ]) + 1.
		Smalltalk globals at: #AgentAutomationSmokeCount put: count.
		^ count = 2
			ifTrue: [ AgentAutomationResult changed: ''second run changed something'' ]
			ifFalse: [ AgentAutomationResult unchanged: ''smoke run completed'' ]'.

	now := DateAndTime now.
	routine := class new
		schedule: (AgentSchedule everyMinutes: 5) at: now;
		dependencies: #(AgentTool);
		register;
		yourself.
	routine verifyAndEnableAt: now.
	due := now + 5 minutes.
	AgentScheduler current tickAt: due.
	AgentScheduler current tickAt: due.
	count := Smalltalk globals at: #AgentAutomationSmokeCount.

	card := AgentAutomationCard cardFor: routine.
	card removeFromParent.
	AgentCanvas current undoDeletion.

	AgentScheduler current resumeSchedulesAt: due + 20 minutes.
	passed := count = 2
		and: [ routine enabled
		and: [ routine history size = 3
		and: [ routine history last status = #missed
		and: [ routine registered
		and: [ (AgentAutomationCard cardFor: routine) == card
		and: [ AgentCanvas current systemMessages size = 1
		and: [ AgentCanvas current systemMessages first body
			includesSubstring: 'second run changed something' ] ] ] ] ] ] ].

	Stdio stdout nextPutAll: 'runs: ' , count printString; lf.
	Stdio stdout nextPutAll: 'status: ' , routine status printString; lf.
	Stdio stdout nextPutAll: 'history: ' , routine history printString; lf.
	Stdio stdout nextPutAll: 'delete/undo restored registration: '
		, routine registered printString; lf.
	Stdio stdout nextPutAll: (passed
		ifTrue: [ 'AUTOMATION SMOKE OK' ]
		ifFalse: [ 'AUTOMATION SMOKE FAILED' ]); lf ]
	ensure: [
		AgentAutomation resetRegistry.
		AgentScheduler reset.
		AgentCanvas reset.
		Smalltalk globals removeKey: #AgentAutomationSmokeCount ifAbsent: [  ].
		(Smalltalk globals
			at: #AgentAutomationSmokeRoutine
			ifAbsent: [ nil ])
			ifNotNil: [ :generated | generated removeFromSystem ] ].
passed
	ifTrue: [ Smalltalk exitSuccess ]
	ifFalse: [ Smalltalk exitFailure ]
