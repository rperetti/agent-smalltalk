"
I reload a preflighted AgentSmalltalk source candidate. The caller owns the
transaction boundary: load, migrate, verify the generated build manifest, then
snapshot. Headless callers work on a disposable copy; live callers taint the
session instead of saving after any failure.
"
Class {
	#name : 'AgentUpdater',
	#superclass : 'Object',
	#classInstVars : [
		'updateTaintedReason'
	],
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
AgentUpdater class >> hasValidBuildManifest: aString [
	^ aString notNil
		and: [ (aString beginsWith: 'AS_UPDATE_V1 git:')
		and: [ aString includesSubstring: ' sha256:' ] ]
]

{ #category : 'verification' }
AgentUpdater class >> loadedBuildManifest [
	| marker |
	marker := Smalltalk globals at: #AgentUpdateBuild ifAbsent: [ ^ nil ].
	^ marker manifest
]

{ #category : 'verification' }
AgentUpdater class >> manifestsMatch: actualManifest expected: expectedManifest [
	^ actualManifest = expectedManifest
		and: [ self hasValidBuildManifest: actualManifest ]
]

{ #category : 'verification' }
AgentUpdater class >> verifyLoadedManifest: expectedManifest [
	"The candidate generator writes its exact revision/hash into
	AgentUpdateBuild. This proves the loaded Core package belongs to the same
	candidate that the disposable-image preflight tested; historical selectors
	are not used as revision evidence."
	^ self manifestsMatch: self loadedBuildManifest expected: expectedManifest
]

{ #category : 'updating' }
AgentUpdater class >> updateFromSrc [
	self error: 'Updates require a preflighted source candidate and build manifest'
]

{ #category : 'updating' }
AgentUpdater class >> updateFromSrc: src expectingManifest: expectedManifest [
	"Load one immutable candidate, migrate it, and prove the loaded build marker
	before the caller decides whether it may snapshot."
	self canSaveVerifiedUpdate ifFalse: [
		self error: 'This session is tainted by a failed update; quit without saving and restart the known-good image' ].
	(self hasValidBuildManifest: expectedManifest) ifFalse: [
		self error: 'Invalid update build manifest' ].
	self packageNames do: [ :pkgName |
		| reader |
		reader := TonelReader on: src fileName: pkgName.
		reader loadDefinitions.
		MCPackageLoader updatePackage: (MCPackage named: pkgName) withSnapshot: reader snapshot.
		pkgName = self packageNames first ifTrue: [ self maybeInjectFailureAt: 'load' ] ].
	self runMigrations.
	(self verifyLoadedManifest: expectedManifest) ifFalse: [
		self error: 'Loaded build manifest does not match the preflighted candidate' ].
	^ expectedManifest
]

{ #category : 'testing' }
AgentUpdater class >> maybeInjectFailureAt: phaseName [
	"A process-local failure seam for scripts/test-update-atomicity.sh. It is
	inert unless the environment names this phase."
	| requestedPhase |
	requestedPhase := OSEnvironment current at: 'AGENT_UPDATE_FAIL_AT' ifAbsent: [ ^ self ].
	requestedPhase = phaseName ifTrue: [ self error: 'Injected ', phaseName, ' update failure' ]
]

{ #category : 'updating' }
AgentUpdater class >> runMigrations [
	| canvasClass canvas |
	self maybeInjectFailureAt: 'migration'.
	canvasClass := Smalltalk globals at: #AgentCanvas ifAbsent: [ ^ self ].
	canvas := canvasClass current.
	canvas isInteractive
		ifTrue: [ self migrateOnUiThreadOf: canvas ]
		ifFalse: [ canvas migrateAfterUpdate ]
]

{ #category : 'updating' }
AgentUpdater class >> migrateOnUiThreadOf: canvas [
	"Migrate on the UI thread, but return any asynchronous failure to the
	updater. Snapshotting belongs to the verified caller, never a Bloc pulse."
	| done migrationError |
	done := Semaphore new.
	canvas space enqueueTask: ((Smalltalk globals at: #BlTaskAction) new action: [
		[ canvas migrateAfterUpdate ]
			on: Error
			do: [ :error | migrationError := error ].
		done signal ]).
	canvas space requestNextPulse.
	(done waitTimeoutSeconds: 10) ifTrue: [ canvas migrateAfterUpdate ].
	migrationError ifNotNil: [
		self error: 'Canvas migration failed: ', migrationError messageText ]
]

{ #category : 'tainting' }
AgentUpdater class >> canSaveVerifiedUpdate [
	^ self isUpdateTainted not
]

{ #category : 'tainting' }
AgentUpdater class >> clearUpdateTaint [
	updateTaintedReason := nil
]

{ #category : 'tainting' }
AgentUpdater class >> isUpdateTainted [
	^ updateTaintedReason notNil
]

{ #category : 'tainting' }
AgentUpdater class >> taintUpdate: aString [
	"A live load may have changed memory but has not been snapshotted. Refuse to
	call that state a valid update; recovery is a restart from the on-disk image."
	updateTaintedReason := aString.
	[ (Smalltalk globals at: #AgentSystemMessage ifAbsent: [ ^ self ])
		post: 'Live update failed. This session is tainted and was not saved; quit without saving and restart the known-good image.'
		key: #failedImageUpdate ]
		on: Error
		do: [ :ignored |  ]
]

{ #category : 'tainting' }
AgentUpdater class >> updateTaintedReason [
	^ updateTaintedReason
]

{ #category : 'updating' }
AgentUpdater class >> finalizeVerifiedUpdate: manifest [
	"Post the durable update message only after the build marker has verified."
	(self verifyLoadedManifest: manifest) ifFalse: [
		self error: 'Cannot finalize an unverified update' ].
	(Smalltalk globals at: #AgentSystemMessage ifAbsent: [ ^ self ])
		post: 'Tooling updated from preflighted src ('
			, self packageNames size printString , ' packages; '
			, manifest , ').'
		key: #imageUpdate
]

{ #category : 'updating' }
AgentUpdater class >> snapshotVerifiedUpdate: manifest [
	"Called only after load, migration, and manifest verification. This runs on
	the request thread because snapshots inside a Bloc pulse can fail silently."
	self canSaveVerifiedUpdate ifFalse: [
		self error: 'Refusing to save a tainted update session' ].
	self finalizeVerifiedUpdate: manifest.
	Smalltalk snapshot: true andQuit: false
]
