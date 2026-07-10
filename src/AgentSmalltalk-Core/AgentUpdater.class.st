"
I reload the AgentSmalltalk packages from src/ into the running image --
the single implementation behind scripts/update.st (headless), the
heal-in-image script, and AgentRemote's /update endpoint (live GUI session).
In an interactive session, migrations and the snapshot are enqueued onto the
UI thread; headless callers handle saving themselves.
"
Class {
	#name : 'AgentUpdater',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentUpdater class >> packageNames [
	^ #('AgentSmalltalk-Core' 'AgentSmalltalk-UI' 'AgentSmalltalk-Tests' 'AgentSmalltalk-UITests' 'BaselineOfAgentSmalltalk')
]

{ #category : 'accessing' }
AgentUpdater class >> srcDirectory [
	^ FileLocator image asFileReference parent parent / 'src'
]

{ #category : 'testing' }
AgentUpdater class >> isInteractive [
	"Consult the freshly installed UI manager, not Smalltalk isHeadless:
	the latter can be stale when a GUI-saved image resumes headlessly."
	^ (UIManager default isKindOf: NonInteractiveUIManager) not
]

{ #category : 'verification' }
AgentUpdater class >> sentinels [
	"One recently-added selector per package/key class. A compile error
	aborts its containing class's load, so a missing sentinel is proof the
	update did not fully take. Update these when adding classes, not routinely."
	^ {
		AgentRemote class -> #killStrayProcesses.
		AgentProcessManager class -> #terminateAll.
		AgentUpdater class -> #verifySentinels.
		AgentGateway -> #transport:.
		AgentAutomation class -> #contextListing.
		AgentScheduler -> #tickAt:.
		(Smalltalk globals at: #AgentKnowledge) class -> #numberAt:.
		(Smalltalk globals at: #AgentCanvas) -> #announcer.
		(Smalltalk globals at: #AgentCanvas) -> #widgetAddVersion.
		(Smalltalk globals at: #AgentWidget) -> #flashUpdated.
		(Smalltalk globals at: #AgentAutomationCard) -> #restoredToCanvas.
		(Smalltalk globals at: #AgentSpotlight) -> #cancel }
]

{ #category : 'verification' }
AgentUpdater class >> verifySentinels [
	"True only when every sentinel selector is understood -- i.e. every
	watched class compiled fully during the load."
	^ self sentinels allSatisfy: [ :assoc |
		[ assoc key canUnderstand: assoc value ] on: Error do: [ :e | false ] ]
]

{ #category : 'updating' }
AgentUpdater class >> updateFromSrc [
	"Load the packages (diff semantics: removed definitions unload), then
	migrate -- on the UI thread when a live space is pulsing."
	| src |
	src := self srcDirectory.
	self packageNames do: [ :pkgName |
		| reader |
		reader := TonelReader on: src fileName: pkgName.
		reader loadDefinitions.
		MCPackageLoader updatePackage: (MCPackage named: pkgName) withSnapshot: reader snapshot ].
	self runMigrations
]

{ #category : 'updating' }
AgentUpdater class >> runMigrations [
	| canvasClass canvas |
	canvasClass := Smalltalk globals at: #AgentCanvas ifAbsent: [ ^ self ].
	canvas := canvasClass current.
	canvas isInteractive
		ifTrue: [ self migrateOnUiThreadOf: canvas ]
		ifFalse: [
			canvas migrateAfterUpdate.
			self postUpdateMessage ]
]

{ #category : 'updating' }
AgentUpdater class >> migrateOnUiThreadOf: canvas [
	"Migrate + announce on the UI thread (request a pulse; fall back to
	direct execution if none comes -- an idle window cannot contend). The
	snapshot ALWAYS runs here on the calling thread: snapshotting inside a
	Bloc pulse task fails silently (observed: five migrations ran on the UI
	thread, zero saves reached disk)."
	| done |
	done := Semaphore new.
	canvas space enqueueTask: ((Smalltalk globals at: #BlTaskAction) new action: [
		[ canvas migrateAfterUpdate.
		self postUpdateMessage ] ensure: [ done signal ] ]).
	canvas space requestNextPulse.
	(done waitTimeoutSeconds: 10) ifTrue: [
		canvas migrateAfterUpdate.
		self postUpdateMessage ].
	Smalltalk snapshot: true andQuit: false
]

{ #category : 'updating' }
AgentUpdater class >> postUpdateMessage [
	"The system's voice: announce updates the user did not initiate. A
	headless (closed-session) update posts too -- the message persists in
	the image and greets the user on next open."
	(Smalltalk globals at: #AgentSystemMessage ifAbsent: [ ^ self ])
		post: 'Tooling updated from src ('
			, self packageNames size printString , ' packages).'
		key: #imageUpdate
]
