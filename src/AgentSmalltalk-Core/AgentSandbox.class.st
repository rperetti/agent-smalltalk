"
I evaluate LLM-generated Pharo code in the running image and answer a plain-text
report the model can act on: 'RESULT: <printString>' on success, 'ERROR: <report>'
on failure. I also keep rotating image backups so a bad evaluation is recoverable.
"
Class {
	#name : 'AgentSandbox',
	#superclass : 'Object',
	#instVars : [
		'timeoutSeconds'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'class initialization' }
AgentSandbox class >> initialize [
	"Run on package load: register for image-startup cleanup."
	SessionManager default unregisterClassNamed: self name.
	SessionManager default registerUserClassNamed: self name
]

{ #category : 'system startup' }
AgentSandbox class >> shutDown: quitting [
	"Never snapshot a live server socket: a saved ZnServer resurrects with
	a dead socket and crashes the next session's accept loop (observed:
	headless boots dying in SocketError). startUp: restarts the listener."
	AgentRemote stop
]

{ #category : 'system startup' }
AgentSandbox class >> startUp: resuming [
	AgentRemote trace: 'AgentSandbox startUp: resuming=' , resuming printString.
	"Stale SSL sessions saved with the image hold dead platform handles;
	their finalizers raise PrimitiveFailed and abort non-interactive
	sessions at startup. Neutralize them: destroy is a no-op once the
	handle is nil."
	resuming ifTrue: [
		(Smalltalk globals at: #ZdcPluginSSLSession ifAbsent: [ nil ])
			ifNotNil: [ :cls |
				cls allInstancesDo: [ :s |
					[ s instVarNamed: #handle put: nil ] on: Error do: [ :e |  ] ] ] ].
	"Restart the listener on BOTH sides of a snapshot: when saving,
	startUp: fires with resuming=false, and shutDown: just stopped it.
	Deferred: Smalltalk isHeadless answers TRUE during GUI startup (the
	display is not up yet), so an immediate attempt self-cancels."
	AgentRemote ensureRunning.
	[ 5 seconds wait. AgentRemote ensureRunning ] forkNamed: 'agent-remote-boot'
]

{ #category : 'initialization' }
AgentSandbox >> initialize [
	super initialize.
	timeoutSeconds := 10
]

{ #category : 'accessing' }
AgentSandbox >> timeoutSeconds [
	^ timeoutSeconds
]

{ #category : 'accessing' }
AgentSandbox >> timeoutSeconds: aNumber [
	timeoutSeconds := aNumber
]

{ #category : 'evaluating' }
AgentSandbox >> evaluate: aString [
	"Evaluate Pharo source and answer a text report for the LLM.
	LLM code arrives with LF line endings (JSON); Pharo source must use CR,
	otherwise the code browser and other tools complain about linefeeds.
	Normalizing here also cleans string literals passed to compile:."
	^ [ self basicEvaluate: aString withInternalLineEndings ]
		valueWithin: timeoutSeconds seconds
		onTimeout: [
			'ERROR: evaluation timed out after ' , timeoutSeconds printString
			, ' seconds. Avoid long-running or infinite loops.' ]
]

{ #category : 'evaluating' }
AgentSandbox >> basicEvaluate: aString [
	^ [ 'RESULT: ' , (self safePrint: (Smalltalk compiler evaluate: aString)) ]
		on: Error
		do: [ :e | self errorReportFor: e ]
]

{ #category : 'evaluating' }
AgentSandbox >> safePrint: anObject [
	^ [ anObject printString ]
		on: Error
		do: [ :e | 'a ' , anObject class name , ' (printString failed: ' , e messageText , ')' ]
]

{ #category : 'evaluating' }
AgentSandbox >> errorReportFor: anError [
	^ String streamContents: [ :s |
		s << 'ERROR: ' << anError class name << ': '
			<< (anError messageText ifNil: [ 'no message text' ]).
		s cr.
		self appendDnuSuggestionsFor: anError on: s.
		s << 'Stack (top frames):'.
		s cr.
		[ | stack |
			stack := anError signalerContext stack.
			(stack first: (8 min: stack size)) do: [ :ctx |
				s << '  ' << ctx printString.
				s cr ] ]
			on: Error
			do: [ :e2 | s << '  (stack unavailable)' ] ]
]

{ #category : 'evaluating' }
AgentSandbox >> appendDnuSuggestionsFor: anError on: s [
	"For doesNotUnderstand, list similar selectors the receiver does understand."
	(anError isKindOf: MessageNotUnderstood) ifFalse: [ ^ self ].
	[ | receiverClass sel fragment candidates |
		receiverClass := anError receiver class.
		sel := anError message selector asString.
		fragment := (sel copyUpTo: $:) asLowercase.
		fragment := fragment copyFrom: 1 to: (fragment size min: 5).
		fragment isEmpty ifTrue: [ ^ self ].
		candidates := (receiverClass allSelectors
			select: [ :each | each asString asLowercase includesSubstring: fragment ])
			asSortedCollection asArray.
		candidates isEmpty ifTrue: [ ^ self ].
		s << 'Similar selectors ' << receiverClass name << ' does understand: '
			<< (candidates first: (8 min: candidates size)) printString.
		s cr ]
		on: Error
		do: [ :ignored |  ]
]

{ #category : 'safety' }
AgentSandbox >> backupImage [
	"Copy the image file (i.e. the last snapshot) to a rotating backup, keeping the newest 5.
	Crude but effective: a corrupted image is recoverable by restoring a backup file."
	| imageFile dir backups target |
	imageFile := FileLocator image asFileReference.
	imageFile exists ifFalse: [ ^ nil ].
	dir := imageFile parent / 'backups'.
	dir ensureCreateDirectory.
	target := dir / ('agent-backup-' , DateAndTime now asUnixTime printString , '.image').
	target exists ifTrue: [ ^ target ].
	imageFile copyTo: target.
	backups := ((dir children select: [ :f | f basename beginsWith: 'agent-backup-' ])
		asSortedCollection: [ :a :b | a basename < b basename ]) asOrderedCollection.
	[ backups size > 5 ] whileTrue: [
		backups first ensureDelete.
		backups removeFirst ].
	^ target
]
