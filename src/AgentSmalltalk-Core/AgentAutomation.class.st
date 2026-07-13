"
I am a durable scheduled routine authored by the agent. My subclasses provide
one narrow #run method; I own registration, schedule state, bounded history,
failure containment, and notification policy.

Creation is deliberately two-stage:
    AgentAutomation
        defineNamed: #MorningWeather
        slots: #(target)
        purpose: 'refresh weather'.
    MorningWeather compile: 'run
        ^ (self requireLiveTarget: target) runAutomatedAction'.
    MorningWeather
        registerOn: (AgentSchedule dailyAtHour: 7 minute: 0)
        dependencies: #(WeatherService).
    MorningWeather registeredInstance verifyAndEnable.

The final call runs saved Smalltalk in a managed background process. It enables
the schedule only after that first run succeeds. Scheduled runs never invoke
the LLM.
"
Class {
	#name : 'AgentAutomation',
	#superclass : 'Object',
	#instVars : [
		'schedule',
		'enabled',
		'nextRun',
		'lastRun',
		'lastResult',
		'lastError',
		'history',
		'running',
		'registered',
		'verified',
		'dependencies',
		'enableAfterRun',
		'runProcess',
		'enabledBeforeUnregister'
	],
	#classInstVars : [
		'purpose',
		'registry'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'creating' }
AgentAutomation class >> defineNamed: aSymbol purpose: aString [
	^ self defineNamed: aSymbol slots: #() purpose: aString
]

{ #category : 'creating' }
AgentAutomation class >> defineNamed: aSymbol slots: slotSymbols purpose: aString [
	| automationClass |
	automationClass := AgentAutomation << aSymbol asSymbol
		slots: slotSymbols;
		package: 'AgentSmalltalk-Automations';
		install.
	automationClass purpose: aString.
	^ automationClass
]

{ #category : 'accessing' }
AgentAutomation class >> purpose [
	^ purpose
]

{ #category : 'accessing' }
AgentAutomation class >> purpose: aString [
	purpose := aString
]

{ #category : 'registration' }
AgentAutomation class >> registerOn: anAgentSchedule [
	^ self registerOn: anAgentSchedule dependencies: #()
]

{ #category : 'registration' }
AgentAutomation class >> registerOn: anAgentSchedule dependencies: aCollection [
	| existing |
	existing := self registeredInstance.
	existing ifNotNil: [
		existing
			schedule: anAgentSchedule at: DateAndTime now;
			dependencies: aCollection.
		^ existing ].
	^ self new
		schedule: anAgentSchedule at: DateAndTime now;
		dependencies: aCollection;
		register;
		yourself
]

{ #category : 'registration' }
AgentAutomation class >> registeredInstance [
	^ AgentAutomation automations
		detect: [ :automation | automation class == self ]
		ifNone: [ nil ]
]

{ #category : 'registry' }
AgentAutomation class >> registry [
	"Only AgentAutomation itself owns the registry. Generated subclasses
	inherit this method but all callers below explicitly address the base."
	^ registry ifNil: [ registry := OrderedCollection new ]
]

{ #category : 'registry' }
AgentAutomation class >> automations [
	^ self registry asArray
		asSortedCollection: [ :a :b | a name < b name ]
]

{ #category : 'registry' }
AgentAutomation class >> addRegistered: anAutomation [
	AgentScheduler critical: [
		(self registry includes: anAutomation) ifFalse: [
			self registry add: anAutomation ] ]
]

{ #category : 'registry' }
AgentAutomation class >> removeRegistered: anAutomation [
	AgentScheduler critical: [
		self registry remove: anAutomation ifAbsent: [  ] ]
]

{ #category : 'registry' }
AgentAutomation class >> resetRegistry [
	self registry asArray do: [ :automation |
		automation terminateRunProcess ].
	registry := OrderedCollection new
]

{ #category : 'lifecycle' }
AgentAutomation class >> resetRuntimeState [
	self registry do: [ :automation |
		automation clearTransientRunState ]
]

{ #category : 'context' }
AgentAutomation class >> contextListing [
	^ String streamContents: [ :s |
		s << '## Scheduled automations'.
		s cr.
		self automations
			ifEmpty: [
				s << '(none)'.
				s cr ]
			ifNotEmpty: [ :items |
				items do: [ :automation |
					s << '- ' << automation contextDescription.
					s cr ] ] ]
]

{ #category : 'cards' }
AgentAutomation class >> summonCardFor: anAutomation [
	(Smalltalk globals at: #AgentAutomationCard ifAbsent: [ ^ self ])
		ifNotNil: [ :cardClass |
			[ cardClass summonFor: anAutomation ]
				on: Error
				do: [ :ignored |  ] ]
]

{ #category : 'cards' }
AgentAutomation class >> refreshCardFor: anAutomation [
	(Smalltalk globals at: #AgentAutomationCard ifAbsent: [ ^ self ])
		ifNotNil: [ :cardClass |
			[ cardClass refreshFor: anAutomation ]
				on: Error
				do: [ :ignored |  ] ]
]

{ #category : 'cards' }
AgentAutomation class >> removeCardFor: anAutomation [
	(Smalltalk globals at: #AgentAutomationCard ifAbsent: [ ^ self ])
		ifNotNil: [ :cardClass |
			[ cardClass removeFor: anAutomation ]
				on: Error
				do: [ :ignored |  ] ]
]

{ #category : 'initialization' }
AgentAutomation >> initialize [
	super initialize.
	enabled := false.
	running := false.
	registered := false.
	verified := false.
	dependencies := #().
	history := OrderedCollection new
]

{ #category : 'accessing' }
AgentAutomation >> name [
	^ self class name
]

{ #category : 'accessing' }
AgentAutomation >> purpose [
	^ self class purpose ifNil: [ 'no purpose' ]
]

{ #category : 'accessing' }
AgentAutomation >> schedule [
	^ schedule
]

{ #category : 'accessing' }
AgentAutomation >> schedule: anAgentSchedule [
	self schedule: anAgentSchedule at: DateAndTime now
]

{ #category : 'accessing' }
AgentAutomation >> schedule: anAgentSchedule at: aDateAndTime [
	(anAgentSchedule isKindOf: AgentSchedule) ifFalse: [
		self error: 'Automations require an AgentSchedule' ].
	schedule := anAgentSchedule.
	nextRun := schedule nextAfter: aDateAndTime.
	self refreshCard
]

{ #category : 'accessing' }
AgentAutomation >> dependencies: aCollection [
	dependencies := aCollection collect: [ :each |
		each isBehavior
			ifTrue: [ each name asSymbol ]
			ifFalse: [ each asSymbol ] ].
	self refreshCard
]

{ #category : 'accessing' }
AgentAutomation >> dependencies [
	^ dependencies ifNil: [ #() ]
]

{ #category : 'accessing' }
AgentAutomation >> enabled [
	^ enabled == true
]

{ #category : 'accessing' }
AgentAutomation >> verified [
	^ verified == true
]

{ #category : 'accessing' }
AgentAutomation >> running [
	^ running == true
]

{ #category : 'accessing' }
AgentAutomation >> registered [
	^ registered == true
]

{ #category : 'accessing' }
AgentAutomation >> nextRun [
	^ nextRun
]

{ #category : 'accessing' }
AgentAutomation >> lastRun [
	^ lastRun
]

{ #category : 'accessing' }
AgentAutomation >> lastResult [
	^ lastResult
]

{ #category : 'accessing' }
AgentAutomation >> lastError [
	^ lastError
]

{ #category : 'accessing' }
AgentAutomation >> history [
	^ history ifNil: [ history := OrderedCollection new ]
]

{ #category : 'accessing' }
AgentAutomation >> status [
	self running ifTrue: [ ^ #running ].
	lastError ifNotNil: [ ^ #failed ].
	self verified ifFalse: [ ^ #unverified ].
	self enabled ifFalse: [ ^ #paused ].
	lastRun ifNotNil: [ ^ #succeeded ].
	^ #ready
]

{ #category : 'registration' }
AgentAutomation >> register [
	schedule ifNil: [ self error: 'Set a schedule before registration' ].
	self registered ifTrue: [ ^ self ].
	registered := true.
	AgentAutomation addRegistered: self.
	AgentAutomation summonCardFor: self.
	self refreshCard
]

{ #category : 'registration' }
AgentAutomation >> unregister [
	self unregisterFromCard.
	AgentAutomation removeCardFor: self
]

{ #category : 'registration' }
AgentAutomation >> unregisterFromCard [
	self registered ifFalse: [ ^ self ].
	enabledBeforeUnregister := self enabled.
	registered := false.
	enabled := false.
	self terminateRunProcess.
	AgentAutomation removeRegistered: self
]

{ #category : 'registration' }
AgentAutomation >> restoreRegistration [
	^ self restoreRegistrationAt: DateAndTime now
]

{ #category : 'registration' }
AgentAutomation >> restoreRegistrationAt: aDateAndTime [
	self registered ifTrue: [ ^ self ].
	registered := true.
	enabled := enabledBeforeUnregister == true and: [ self verified ].
	enabledBeforeUnregister := nil.
	(self enabled and: [ nextRun notNil and: [ nextRun <= aDateAndTime ] ])
		ifTrue: [ nextRun := schedule nextAfter: aDateAndTime ].
	AgentAutomation addRegistered: self.
	self refreshCard
]

{ #category : 'lifecycle' }
AgentAutomation >> pause [
	enabled := false.
	self refreshCard
]

{ #category : 'lifecycle' }
AgentAutomation >> resume [
	^ self resumeAt: DateAndTime now
]

{ #category : 'lifecycle' }
AgentAutomation >> resumeAt: aDateAndTime [
	self verified ifFalse: [
		self error: 'Run now successfully before enabling this automation' ].
	self registered ifFalse: [
		self error: 'Register this automation before enabling it' ].
	enabled := true.
	nextRun := schedule nextAfter: aDateAndTime.
	self refreshCard
]

{ #category : 'running' }
AgentAutomation >> runNow [
	^ AgentScheduler current runNow: self
]

{ #category : 'running' }
AgentAutomation >> verifyAndEnable [
	^ AgentScheduler current verifyAndEnable: self
]

{ #category : 'running' }
AgentAutomation >> runNowAt: aDateAndTime [
	(AgentScheduler
		claimManual: self
		at: aDateAndTime
		enableOnSuccess: false
		preserveSchedule: true)
		ifTrue: [ self executeClaimedAt: aDateAndTime ].
	^ self
]

{ #category : 'running' }
AgentAutomation >> verifyAndEnableAt: aDateAndTime [
	(AgentScheduler claimManual: self at: aDateAndTime enableOnSuccess: true)
		ifTrue: [ self executeClaimedAt: aDateAndTime ].
	^ self
]

{ #category : 'running' }
AgentAutomation >> claimScheduledAt: aDateAndTime [
	(self registered and: [
		self enabled and: [
		self running not and: [
		nextRun notNil and: [ nextRun <= aDateAndTime ] ] ] ])
		ifFalse: [ ^ false ].
	running := true.
	enableAfterRun := false.
	nextRun := schedule nextAfter: aDateAndTime.
	self refreshCard.
	^ true
]

{ #category : 'running' }
AgentAutomation >> claimManualAt: aDateAndTime enableOnSuccess: aBoolean [
	^ self
		claimManualAt: aDateAndTime
		enableOnSuccess: aBoolean
		preserveSchedule: false
]

{ #category : 'running' }
AgentAutomation >> claimManualAt: aDateAndTime enableOnSuccess: aBoolean preserveSchedule: preserveSchedule [
	(self registered and: [ self running not ]) ifFalse: [ ^ false ].
	running := true.
	enableAfterRun := aBoolean.
	preserveSchedule ifFalse: [ nextRun := schedule nextAfter: aDateAndTime ].
	self refreshCard.
	^ true
]

{ #category : 'running' }
AgentAutomation >> executeClaimedAt: startedAt [
	| raw result finishedAt |
	[
		self validateDependencies.
		raw := [ self run ]
			valueWithin: self timeoutSeconds seconds
			onTimeout: [
				self error: 'run timed out after '
					, self timeoutSeconds printString , ' seconds' ].
		result := self normalizeResult: raw.
		finishedAt := DateAndTime now.
		self completeSuccess: result startedAt: startedAt finishedAt: finishedAt ]
		on: Error
		do: [ :error |
			finishedAt := DateAndTime now.
			self
				completeFailure: error
				startedAt: startedAt
				finishedAt: finishedAt ]
]

{ #category : 'running' }
AgentAutomation >> run [
	self subclassResponsibility
]

{ #category : 'running' }
AgentAutomation >> timeoutSeconds [
	^ 30
]

{ #category : 'running' }
AgentAutomation >> validateDependencies [
	self dependencies do: [ :dependency |
		Smalltalk globals
			at: dependency
			ifAbsent: [
				self error: 'required dependency is missing: '
					, dependency asString ] ]
]

{ #category : 'running' }
AgentAutomation >> requireLiveTarget: aWidget [
	| canvasClass |
	canvasClass := Smalltalk globals
		at: #AgentCanvas
		ifAbsent: [ self error: 'the canvas is unavailable' ].
	(canvasClass current containsWidget: aWidget) ifFalse: [
		self error: 'the target widget is no longer on the canvas' ].
	^ aWidget
]

{ #category : 'running' }
AgentAutomation >> normalizeResult: anObject [
	(anObject isKindOf: AgentAutomationResult) ifTrue: [ ^ anObject ].
	^ AgentAutomationResult unchanged: (self safeSummaryOf: anObject)
]

{ #category : 'running' }
AgentAutomation >> completeSuccess: aResult startedAt: start finishedAt: finish [
	lastRun := start.
	lastResult := aResult.
	lastError := nil.
	verified := true.
	enableAfterRun == true ifTrue: [ enabled := true ].
	enableAfterRun := false.
	running := false.
	runProcess := nil.
	self addHistory: (AgentAutomationRun
		status: #succeeded
		startedAt: start
		finishedAt: finish
		summary: aResult summary).
	aResult isChanged ifTrue: [
		self
			postSystemMessage: self name , ': ' , aResult summary
			key: ('automationChange-' , self name) asSymbol ].
	self refreshCard
]

{ #category : 'running' }
AgentAutomation >> completeFailure: anError startedAt: start finishedAt: finish [
	lastRun := start.
	lastError := anError messageText ifNil: [ anError class name ].
	enableAfterRun := false.
	running := false.
	runProcess := nil.
	self addHistory: (AgentAutomationRun
		status: #failed
		startedAt: start
		finishedAt: finish
		summary: lastError).
	self
		postSystemMessage: self name , ' failed: ' , lastError
		key: ('automationFailure-' , self name) asSymbol.
	self refreshCard
]

{ #category : 'history' }
AgentAutomation >> addHistory: aRun [
	self history addLast: aRun.
	[ self history size > 20 ] whileTrue: [ self history removeFirst ]
]

{ #category : 'history' }
AgentAutomation >> noteMissedAt: aDateAndTime [
	self addHistory: (AgentAutomationRun missedAt: aDateAndTime).
	nextRun := schedule nextAfter: aDateAndTime.
	self refreshCard
]

{ #category : 'processes' }
AgentAutomation >> runProcess: aProcess [
	runProcess := aProcess
]

{ #category : 'processes' }
AgentAutomation >> terminateRunProcess [
	| process |
	process := runProcess.
	runProcess := nil.
	running := false.
	process ifNotNil: [
		(process ~~ Processor activeProcess and: [ process isTerminated not ])
			ifTrue: [
				[ process terminate ] on: Error do: [ :ignored |  ] ] ]
]

{ #category : 'processes' }
AgentAutomation >> clearTransientRunState [
	running := false.
	enableAfterRun := false.
	runProcess := nil
]

{ #category : 'private' }
AgentAutomation >> safeSummaryOf: anObject [
	^ [ anObject printString ]
		on: Error
		do: [ :ignored | 'completed' ]
]

{ #category : 'private' }
AgentAutomation >> postSystemMessage: aString key: aSymbol [
	(Smalltalk globals at: #AgentSystemMessage ifAbsent: [ ^ self ])
		ifNotNil: [ :messageClass |
			[ messageClass post: aString key: aSymbol ]
				on: Error
				do: [ :ignored |  ] ]
]

{ #category : 'private' }
AgentAutomation >> refreshCard [
	AgentAutomation refreshCardFor: self
]

{ #category : 'context' }
AgentAutomation >> contextDescription [
	^ String streamContents: [ :s |
		s << self name << ' -- ' << self purpose.
		s << '; ' << schedule describe.
		s << '; ' << self status asString.
		nextRun ifNotNil: [ s << '; next ' << nextRun printString ].
		lastRun ifNotNil: [ s << '; last ' << lastRun printString ].
		self dependencies ifNotEmpty: [
			s << '; uses '.
			self dependencies
				do: [ :each | s << each asString ]
				separatedBy: [ s << ', ' ] ] ]
]

{ #category : 'printing' }
AgentAutomation >> printOn: aStream [
	aStream
		nextPutAll: self name;
		nextPutAll: ' (';
		nextPutAll: self status asString;
		nextPut: $)
]
