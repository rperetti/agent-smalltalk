"
I am the living image's ear: a localhost-only HTTP listener (port 8807) so
tooling outside the process can update the RUNNING session instead of
refusing (update.sh) or requiring a Playground paste. Endpoints:
  GET  /ping    -- liveness check
  POST /update  -- AgentUpdater updateFromSrc (reload our packages, migrate
                   on the UI thread, save)
  POST /eval    -- evaluate the request body via AgentSandbox; answers the
                   RESULT:/ERROR: report. Operator diagnostics for the live
                   session (localhost-only; same trust level as the gateway,
                   which already executes generated code).
I never start in non-interactive sessions.
"
Class {
	#name : 'AgentRemote',
	#superclass : 'Object',
	#classInstVars : [
		'server'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentRemote class >> port [
	^ 8807
]

{ #category : 'running' }
AgentRemote class >> ensureRunning [
	"Guard on the VM flag, not UIManager: during GUI startup the UIManager
	is still non-interactive, which silently blocked the listener. All
	setup is inside the handler and failures are LOGGED (logs/remote.log)
	-- silent swallowing cost us a debugging session. The watchdog retries
	every 30s, so a transient boot-time failure heals itself."
	Smalltalk isHeadless ifTrue: [ ^ nil ].
	self startWatchdog.
	(server notNil and: [ server isRunning ]) ifTrue: [ ^ server ].
	[ | s |
		s := ZnServer on: self port.
		s bindingAddress: NetNameResolver loopBackAddress.
		s onRequestRespond: [ :request | self handleRequest: request ].
		s start.
		s isRunning
			ifTrue: [ server := s ]
			ifFalse: [
				self logFailure: 'server started but is not running'.
				server := nil ] ]
		on: Error
		do: [ :e |
			self logFailure: e class name , ': ' , (e messageText ifNil: [ '' ]).
			server := nil ].
	^ server
]

{ #category : 'running' }
AgentRemote class >> startWatchdog [
	"One background process that revives the listener if it is ever down.
	Identified by process name so saves/reopens cannot duplicate it."
	(Process allSubInstances anySatisfy: [ :p |
		p name = 'agent-remote-watchdog' and: [ p isTerminated not ] ])
		ifTrue: [ ^ self ].
	[ [ true ] whileTrue: [
		30 seconds wait.
		[ Smalltalk isHeadless ifFalse: [
			(server notNil and: [ server isRunning ]) ifFalse: [ self ensureRunning ] ] ]
			on: Error do: [ :e |  ] ] ]
		forkNamed: 'agent-remote-watchdog'
]

{ #category : 'running' }
AgentRemote class >> logFailure: aString [
	[ | ref stream |
	ref := (FileLocator image asFileReference parent parent / 'logs')
		ensureCreateDirectory; / 'remote.log'.
	stream := ref writeStream.
	stream setToEnd.
	stream nextPutAll: DateAndTime now printString , ' | ' , aString.
	stream lf.
	stream close ]
		on: Error
		do: [ :e |  ]
]

{ #category : 'running' }
AgentRemote class >> stop [
	server ifNotNil: [ [ server stop ] on: Error do: [ :e |  ] ].
	server := nil
]

{ #category : 'running' }
AgentRemote class >> handleRequest: request [
	"ZnUrl>>path answers the path without its leading slash."
	request uri path = 'ping' ifTrue: [
		^ ZnResponse ok: (ZnEntity text: 'agent-smalltalk alive') ].
	(request uri path = 'update' and: [ request method = #POST ]) ifTrue: [
		^ [ AgentUpdater updateFromSrc.
			ZnResponse ok: (ZnEntity text: 'updated') ]
			on: Error
			do: [ :e | ZnResponse serverError: e messageText ] ].
	(request uri path = 'eval' and: [ request method = #POST ]) ifTrue: [
		^ ZnResponse ok: (ZnEntity text: (AgentSandbox new evaluate: request contents)) ].
	^ ZnResponse notFound: request uri
]
