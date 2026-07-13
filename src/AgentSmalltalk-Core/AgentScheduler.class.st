"
I am the single supervised ticker for AgentAutomation. Production uses one
managed polling process and forks each claimed run. #tickAt: executes claimed
runs synchronously so nearly all scheduling behavior is deterministic and
headless-testable.
"
Class {
	#name : 'AgentScheduler',
	#superclass : 'Object',
	#instVars : [
		'process'
	],
	#classInstVars : [
		'current',
		'claimMutex'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentScheduler class >> current [
	^ current ifNil: [ current := self new ]
]

{ #category : 'locking' }
AgentScheduler class >> claimMutex [
	^ claimMutex ifNil: [ claimMutex := Semaphore forMutualExclusion ]
]

{ #category : 'locking' }
AgentScheduler class >> critical: aBlock [
	^ self claimMutex critical: aBlock
]

{ #category : 'locking' }
AgentScheduler class >> resetMutex [
	claimMutex := Semaphore forMutualExclusion
]

{ #category : 'testing' }
AgentScheduler class >> reset [
	current ifNotNil: [ current stop ].
	current := nil.
	self resetMutex
]

{ #category : 'claiming' }
AgentScheduler class >> claimManual: anAutomation at: aDateAndTime enableOnSuccess: aBoolean [
	^ self
		claimManual: anAutomation
		at: aDateAndTime
		enableOnSuccess: aBoolean
		preserveSchedule: false
]

{ #category : 'claiming' }
AgentScheduler class >> claimManual: anAutomation at: aDateAndTime enableOnSuccess: aBoolean preserveSchedule: preserveSchedule [
	^ self critical: [
		anAutomation
			claimManualAt: aDateAndTime
			enableOnSuccess: aBoolean
			preserveSchedule: preserveSchedule ]
]

{ #category : 'running' }
AgentScheduler >> start [
	| existing |
	(UIManager default isKindOf: NonInteractiveUIManager) ifTrue: [ ^ self ].
	(process notNil and: [ process isTerminated not ]) ifTrue: [ ^ self ].
	existing := Process allSubInstances
		detect: [ :each |
			each name = 'agent-automation-scheduler'
				and: [ each isTerminated not ] ]
		ifNone: [ nil ].
	existing ifNotNil: [
		process := existing.
		^ self ].
	self resumeSchedulesAt: DateAndTime now.
	process := [
		[ true ] whileTrue: [
			30 seconds wait.
			[ self tickAsyncAt: DateAndTime now ]
				on: Error
				do: [ :ignored |  ] ] ]
		forkNamed: 'agent-automation-scheduler'
]

{ #category : 'running' }
AgentScheduler >> stop [
	process ifNotNil: [
		(process ~~ Processor activeProcess and: [ process isTerminated not ])
			ifTrue: [
				[ process terminate ] on: Error do: [ :ignored |  ] ] ].
	process := nil
]

{ #category : 'running' }
AgentScheduler >> isRunning [
	^ process notNil and: [ process isTerminated not ]
]

{ #category : 'running' }
AgentScheduler >> tickAt: aDateAndTime [
	| claimed |
	claimed := self claimDueAt: aDateAndTime.
	claimed do: [ :automation |
		automation executeClaimedAt: aDateAndTime ].
	^ claimed
]

{ #category : 'running' }
AgentScheduler >> tickAsyncAt: aDateAndTime [
	(self claimDueAt: aDateAndTime) do: [ :automation |
		self startClaimed: automation at: aDateAndTime ]
]

{ #category : 'claiming' }
AgentScheduler >> claimDueAt: aDateAndTime [
	^ self class critical: [
		AgentAutomation automations select: [ :automation |
			automation claimScheduledAt: aDateAndTime ] ]
]

{ #category : 'running' }
AgentScheduler >> runNow: anAutomation [
	| now |
	now := DateAndTime now.
	(self class
		claimManual: anAutomation
		at: now
		enableOnSuccess: false
		preserveSchedule: true)
		ifTrue: [
			self startClaimed: anAutomation at: now ].
	^ anAutomation
]

{ #category : 'running' }
AgentScheduler >> verifyAndEnable: anAutomation [
	(self class
		claimManual: anAutomation
		at: DateAndTime now
		enableOnSuccess: true)
		ifTrue: [
			self startClaimed: anAutomation at: DateAndTime now ].
	^ anAutomation
]

{ #category : 'running' }
AgentScheduler >> startClaimed: anAutomation at: aDateAndTime [
	| run |
	run := [
		anAutomation executeClaimedAt: aDateAndTime ]
		forkNamed: 'agent-automation-' , anAutomation name.
	anAutomation runProcess: run.
	^ run
]

{ #category : 'lifecycle' }
AgentScheduler >> resumeSchedulesAt: aDateAndTime [
	"Image-closed semantics: record one missed entry and move to the next
	future occurrence. Never catch up by executing old work."
	AgentAutomation automations do: [ :automation |
		(automation enabled and: [
			automation nextRun notNil and: [
			automation nextRun <= aDateAndTime ] ])
			ifTrue: [ automation noteMissedAt: aDateAndTime ] ]
]
