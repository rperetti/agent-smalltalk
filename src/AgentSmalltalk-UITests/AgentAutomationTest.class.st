"
Deterministic tests for schedules, registration, supervised execution,
history, notifications, missed-run semantics, and card deletion/undo.
"
Class {
	#name : 'AgentAutomationTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentAutomationTest >> setUp [
	super setUp.
	AgentScheduler reset.
	AgentAutomation resetRegistry.
	AgentCanvas reset.
	AgentAutomationTestProbe purpose: 'exercise scheduled work'
]

{ #category : 'running' }
AgentAutomationTest >> tearDown [
	AgentAutomation resetRegistry.
	AgentScheduler reset.
	AgentCanvas reset.
	super tearDown
]

{ #category : 'support' }
AgentAutomationTest >> timeAtHour: hour minute: minute [
	^ DateAndTime
		year: 2026
		month: 7
		day: 9
		hour: hour
		minute: minute
		second: 0
		offset: 0 hours
]

{ #category : 'support' }
AgentAutomationTest >> newAutomationAt: aDateAndTime everyMinutes: minutes [
	^ AgentAutomationTestProbe new
		schedule: (AgentSchedule everyMinutes: minutes) at: aDateAndTime;
		dependencies: #(AgentTool);
		register;
		yourself
]

{ #category : 'tests - schedules' }
AgentAutomationTest >> testIntervalSchedulesAnswerNextOccurrence [
	| now |
	now := self timeAtHour: 10 minute: 15.
	self
		assert: ((AgentSchedule everyMinutes: 5) nextAfter: now)
		equals: now + 5 minutes.
	self
		assert: ((AgentSchedule everyHours: 2) nextAfter: now)
		equals: now + 2 hours
]

{ #category : 'tests - schedules' }
AgentAutomationTest >> testDailyScheduleUsesNextLocalOccurrence [
	| morning atSeven |
	morning := self timeAtHour: 6 minute: 30.
	atSeven := AgentSchedule dailyAtHour: 7 minute: 0.
	self
		assert: (atSeven nextAfter: morning)
		equals: (self timeAtHour: 7 minute: 0).
	self
		assert: (atSeven nextAfter: (self timeAtHour: 8 minute: 0))
		equals: (self timeAtHour: 7 minute: 0) + 1 day
]

{ #category : 'tests - schedules' }
AgentAutomationTest >> testInvalidIntervalIsRejected [
	self
		should: [ AgentSchedule everyMinutes: 0 ]
		raise: Error.
	self
		should: [ AgentSchedule everyMinutes: 0.5 ]
		raise: Error
]

{ #category : 'tests - schedules' }
AgentAutomationTest >> testDailyScheduleRejectsSecondPrecision [
	self
		should: [
			AgentSchedule dailyAt:
				(Time hour: 7 minute: 0 second: 30) ]
		raise: Error
]

{ #category : 'tests - registration' }
AgentAutomationTest >> testRegistrationCreatesPausedRoutineAndCard [
	| automation card |
	self assert: AgentAutomationCard nextPosition equals: 500 @ 620.
	automation := self
		newAutomationAt: (self timeAtHour: 9 minute: 0)
		everyMinutes: 5.
	self assert: AgentAutomation automations size equals: 1.
	self deny: automation enabled.
	self assert: automation status equals: #unverified.
	card := AgentCanvas current widgets
		detect: [ :widget | widget isKindOf: AgentAutomationCard ].
	self assert: card automation identicalTo: automation.
	self assert: AgentAutomationCard nextPosition equals: 518 @ 638
]

{ #category : 'tests - registration' }
AgentAutomationTest >> testRepeatedRegistrationUpdatesRatherThanDuplicates [
	| first second |
	first := AgentAutomationTestProbe
		registerOn: (AgentSchedule everyMinutes: 5)
		dependencies: #(OldService).
	second := AgentAutomationTestProbe
		registerOn: (AgentSchedule everyHours: 2)
		dependencies: #(NewService).
	self assert: second identicalTo: first.
	self assert: AgentAutomation automations size equals: 1.
	self assert: (AgentCanvas current widgets count: [ :widget |
		widget isKindOf: AgentAutomationCard ]) equals: 1.
	self assert: second schedule describe equals: 'every 2 hours'.
	self assert: second dependencies equals: #(NewService)
]

{ #category : 'tests - registration' }
AgentAutomationTest >> testBlessedDefinitionSupportsLiveTargetSlots [
	| generated |
	[
		generated := AgentAutomation
			defineNamed: #AgentAutomationSlotProbe
			slots: #(target)
			purpose: 'retain a live target'.
		self assert: (generated inheritsFrom: AgentAutomation).
		self assert: generated instVarNames equals: #('target').
		self assert: generated purpose equals: 'retain a live target'.
		self assert: generated package name
			equals: 'AgentSmalltalk-Automations' ]
		ensure: [
			(Smalltalk globals
				at: #AgentAutomationSlotProbe
				ifAbsent: [ nil ])
				ifNotNil: [ :class | class removeFromSystem ] ]
]

{ #category : 'tests - registration' }
AgentAutomationTest >> testDeletingCardUnregistersAndUndoRestores [
	| automation card now |
	now := self timeAtHour: 9 minute: 0.
	automation := self
		newAutomationAt: now
		everyMinutes: 5.
	automation verifyAndEnableAt: now.
	card := AgentAutomationCard cardFor: automation.
	card removeFromParent.
	self deny: automation registered.
	self deny: automation enabled.
	self assert: AgentAutomation automations isEmpty.
	AgentCanvas current undoDeletion.
	self assert: automation registered.
	self assert: automation enabled.
	self assert: (AgentAutomation automations includes: automation).
	self assert: (AgentAutomationCard cardFor: automation) identicalTo: card
]

{ #category : 'tests - running' }
AgentAutomationTest >> testVerificationRunsOnceAndEnablesAfterSuccess [
	| now automation |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	automation verifyAndEnableAt: now.
	self assert: automation runCount equals: 1.
	self assert: automation verified.
	self assert: automation enabled.
	self assert: automation lastError isNil.
	self assert: automation history size equals: 1.
	self assert: automation nextRun equals: now + 5 minutes
]

{ #category : 'tests - running' }
AgentAutomationTest >> testFailedVerificationDoesNotEnable [
	| now automation |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	automation action: [ self error: 'verification broke' ].
	automation verifyAndEnableAt: now.
	self deny: automation enabled.
	self deny: automation verified.
	self assert: (automation lastError includesSubstring: 'verification broke')
]

{ #category : 'tests - running' }
AgentAutomationTest >> testDueTickRunsExactlyOnce [
	| now automation scheduler due |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	automation verifyAndEnableAt: now.
	scheduler := AgentScheduler current.
	due := now + 5 minutes.
	scheduler tickAt: due.
	scheduler tickAt: due.
	self assert: automation runCount equals: 2.
	self assert: automation nextRun equals: due + 5 minutes
]

{ #category : 'tests - running' }
AgentAutomationTest >> testPausedAndFutureAutomationsDoNotRun [
	| now automation scheduler |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	automation verifyAndEnableAt: now.
	scheduler := AgentScheduler current.
	scheduler tickAt: now + 2 minutes.
	self assert: automation runCount equals: 1.
	automation pause.
	scheduler tickAt: now + 5 minutes.
	self assert: automation runCount equals: 1
]

{ #category : 'tests - running' }
AgentAutomationTest >> testFailureDoesNotStopAnotherDueRoutine [
	| now broken healthy scheduler due |
	now := self timeAtHour: 9 minute: 0.
	broken := self newAutomationAt: now everyMinutes: 5.
	healthy := self newAutomationAt: now everyMinutes: 5.
	broken verifyAndEnableAt: now.
	healthy verifyAndEnableAt: now.
	broken action: [ self error: 'service exploded' ].
	scheduler := AgentScheduler current.
	due := now + 5 minutes.
	scheduler tickAt: due.
	self assert: broken runCount equals: 2.
	self assert: healthy runCount equals: 2.
	self assert: (broken lastError includesSubstring: 'service exploded').
	self assert: AgentCanvas current systemMessages size equals: 1
]

{ #category : 'tests - lifecycle' }
AgentAutomationTest >> testResumeRequiresSuccessfulRun [
	| automation |
	automation := self
		newAutomationAt: (self timeAtHour: 9 minute: 0)
		everyMinutes: 5.
	self
		should: [ automation resume ]
		raise: Error
]

{ #category : 'tests - lifecycle' }
AgentAutomationTest >> testMissedRunIsRecordedButNotExecutedOrAnnounced [
	| now automation reopen |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	automation verifyAndEnableAt: now.
	reopen := now + 20 minutes.
	AgentScheduler current resumeSchedulesAt: reopen.
	self assert: automation runCount equals: 1.
	self assert: automation history last status equals: #missed.
	self assert: automation nextRun equals: reopen + 5 minutes.
	self assert: AgentCanvas current systemMessages isEmpty
]

{ #category : 'tests - results' }
AgentAutomationTest >> testChangedResultPostsMessageButUnchangedStaysQuiet [
	| now automation |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	automation runNowAt: now.
	self assert: AgentCanvas current systemMessages isEmpty.
	automation action: [
		AgentAutomationResult changed: 'rain begins soon' ].
	automation runNowAt: now + 1 minute.
	self assert: AgentCanvas current systemMessages size equals: 1.
	self assert: (AgentCanvas current systemMessages first body
		includesSubstring: 'rain begins soon')
]

{ #category : 'tests - history' }
AgentAutomationTest >> testHistoryIsBoundedAtTwenty [
	| now automation |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	25 timesRepeat: [
		automation runNowAt: now.
		now := now + 1 minute ].
	self assert: automation history size equals: 20
]

{ #category : 'tests - context' }
AgentAutomationTest >> testContextListsStateAndDependenciesNotImplementation [
	| automation listing |
	automation := self
		newAutomationAt: (self timeAtHour: 9 minute: 0)
		everyMinutes: 5.
	listing := AgentAutomation contextListing.
	self assert: (listing includesSubstring: automation name).
	self assert: (listing includesSubstring: 'exercise scheduled work').
	self assert: (listing includesSubstring: 'every 5 minutes').
	self assert: (listing includesSubstring: 'AgentTool').
	self deny: (listing includesSubstring: 'action value')
]

{ #category : 'tests - context' }
AgentAutomationTest >> testAutomationCardStaysOutOfWidgetContext [
	self
		newAutomationAt: (self timeAtHour: 9 minute: 0)
		everyMinutes: 5.
	self deny: (AgentCanvas current contextDescription
		includesSubstring: 'AgentAutomationTestProbe')
]

{ #category : 'tests - processes' }
AgentAutomationTest >> testAutomationProcessesAreManaged [
	self assert: (AgentProcessManager
		managesName: 'agent-automation-AgentAutomationTestProbe').
	self assert: (AgentProcessManager
		managesName: 'agent-automation-scheduler')
]

{ #category : 'tests - processes' }
AgentAutomationTest >> testSnapshotCleanupClearsTransientRunningState [
	| now automation |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	self assert: (automation
		claimManualAt: now
		enableOnSuccess: false).
	self assert: automation running.
	AgentAutomation resetRuntimeState.
	self deny: automation running
]

{ #category : 'tests - reliability' }
AgentAutomationTest >> testMissingDependencyFailsVisiblyBeforeRun [
	| now automation |
	now := self timeAtHour: 9 minute: 0.
	automation := self newAutomationAt: now everyMinutes: 5.
	automation dependencies: #(DefinitelyMissingPhase6Service).
	automation verifyAndEnableAt: now.
	self assert: automation runCount equals: 0.
	self deny: automation enabled.
	self assert: (automation lastError
		includesSubstring: 'DefinitelyMissingPhase6Service')
]

{ #category : 'tests - reliability' }
AgentAutomationTest >> testRequireLiveTargetRejectsDeletedWidget [
	| automation widget |
	automation := self
		newAutomationAt: (self timeAtHour: 9 minute: 0)
		everyMinutes: 5.
	widget := AgentWidget new.
	self
		should: [ automation requireLiveTarget: widget ]
		raise: Error.
	AgentCanvas current addWidget: widget.
	self assert: (automation requireLiveTarget: widget) identicalTo: widget.
	widget removeFromParent.
	self
		should: [ automation requireLiveTarget: widget ]
		raise: Error
]

{ #category : 'tests - target contract' }
AgentAutomationTest >> testWidgetAutomationActionDelegatesToRefresh [
	| widget result |
	widget := AgentAutomationTargetProbe new.
	result := widget runAutomatedAction.
	self assert: widget refreshCount equals: 1.
	self deny: result isChanged.
	self assert: (result summary includesSubstring: 'AgentAutomationTargetProbe')
]

{ #category : 'tests - target contract' }
AgentAutomationTest >> testWidgetAutomationActionPreservesExplicitResult [
	| widget result |
	widget := AgentAutomationTargetProbe new.
	widget refreshResult: (AgentAutomationResult changed: 'probe changed').
	result := widget runAutomatedAction.
	self assert: widget refreshCount equals: 1.
	self assert: result isChanged.
	self assert: result summary equals: 'probe changed'
]

{ #category : 'tests - target contract' }
AgentAutomationTest >> testAutomationCanDelegateToLiveTargetAction [
	| now automation widget |
	now := self timeAtHour: 9 minute: 0.
	widget := AgentAutomationTargetProbe new.
	AgentCanvas current addWidget: widget.
	automation := self newAutomationAt: now everyMinutes: 5.
	automation action: [
		(automation requireLiveTarget: widget) runAutomatedAction ].
	automation runNowAt: now.
	self assert: widget refreshCount equals: 1.
	self assert: automation lastResult summary
		equals: 'AgentAutomationTargetProbe refreshed'
]
