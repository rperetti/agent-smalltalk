"
I am the living image's ear: a localhost-only HTTP listener (port 8807) so
tooling outside the process can update the RUNNING session instead of
refusing (update.sh) or requiring a Playground paste. Endpoints:
  GET  /ping    -- liveness check
  POST /update  -- AgentUpdater updateFromSrc (reload packages, migrate, save)
  POST /eval    -- evaluate the request body via AgentSandbox (operator
                   diagnostics; localhost-only, gateway-level trust).

I run ONLY in an interactive GUI session, detected by the `enabled` flag:
every fresh boot resets it to false (AgentSandbox startUp:), and only
AgentCanvas open turns it on. This is the sole poison-proof discriminator --
a headless VM loading a GUI-saved image inherits every saved flag (isHeadless,
space isOpened, even OSWindow instances) as stale truth, but startUp: runs
fresh each launch. Headless updates and probes never call open, so they never
bind the port.
"
Class {
	#name : 'AgentRemote',
	#superclass : 'Object',
	#classInstVars : [
		'server',
		'enabled'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentRemote class >> port [
	^ 8807
]

{ #category : 'enabling' }
AgentRemote class >> enable [
	"Called only from the GUI AgentCanvas open path."
	enabled := true
]

{ #category : 'enabling' }
AgentRemote class >> disable [
	"Called from AgentSandbox startUp: on every fresh boot, so a GUI-saved
	image resumed headless starts with the listener OFF until open re-enables."
	enabled := false.
	self stop
]

{ #category : 'enabling' }
AgentRemote class >> isEnabled [
	^ enabled == true
]

{ #category : 'running' }
AgentRemote class >> ensureRunning [
	"No-op unless this is a GUI session (enabled). Idempotent: a healthy
	server is left alone. Otherwise bury any predecessor and start one,
	polling for the ASYNC listen loop to actually bind."
	self isEnabled ifFalse: [ ^ nil ].
	self startWatchdog.
	(server notNil and: [ server isRunning ]) ifTrue: [ ^ server ].
	self stop.
	[ | s |
		s := ZnServer on: self port.
		s bindingAddress: NetNameResolver loopBackAddress.
		s onRequestRespond: [ :request | self handleRequest: request ].
		s start.
		"start forks the listen loop; isRunning flips true a beat later."
		1 to: 25 do: [ :i | s isRunning ifFalse: [ 200 milliSeconds wait ] ].
		s isRunning
			ifTrue: [ server := s ]
			ifFalse: [
				[ s stop ] on: Error do: [ :e |  ].
				self logFailure: 'server did not reach running state'.
				server := nil ] ]
		on: Error
		do: [ :e |
			self logFailure: e class name , ': ' , (e messageText ifNil: [ '' ]).
			server := nil ].
	^ server
]

{ #category : 'running' }
AgentRemote class >> startWatchdog [
	"One background reviver, gated on enabled and identified by name so
	saves/reopens cannot duplicate it."
	(Process allSubInstances anySatisfy: [ :p |
		p name = 'agent-remote-watchdog' and: [ p isTerminated not ] ])
		ifTrue: [ ^ self ].
	[ [ true ] whileTrue: [
		30 seconds wait.
		[ self isEnabled ifTrue: [
			(server notNil and: [ server isRunning ]) ifFalse: [ self ensureRunning ].
			self writeHeartbeat ] ]
			on: Error do: [ :e |  ] ] ]
		forkNamed: 'agent-remote-watchdog'
]

{ #category : 'running' }
AgentRemote class >> stop [
	"Stop the server AND terminate any stray Zn listen-loop processes bound
	to our port, so a resumed snapshot cannot leave a zombie fighting a new
	server for the bind."
	server ifNotNil: [ [ server stop ] on: Error do: [ :e |  ] ].
	server := nil.
	[ ZnServer allSubInstances do: [ :s |
		(s port = self port) ifTrue: [ [ s stop ] on: Error do: [ :e |  ] ] ] ]
		on: Error do: [ :e |  ]
]

{ #category : 'running' }
AgentRemote class >> writeHeartbeat [
	[ | dir ref |
	dir := FileLocator image asFileReference parent parent / 'logs'.
	dir ensureCreateDirectory.
	ref := dir / 'session.status'.
	ref writeStreamDo: [ :stream |
		stream
			nextPutAll: DateAndTime now printString;
			nextPutAll: ' | listener: ';
			nextPutAll: (server notNil and: [ server isRunning ]) printString;
			lf ] ]
		on: Error do: [ :e |  ]
]

{ #category : 'running' }
AgentRemote class >> logFailure: aString [
	[ | ref stream |
	ref := (FileLocator image asFileReference parent parent / 'logs')
		ensureCreateDirectory; / 'remote.log'.
	stream := ref writeStream.
	stream setToEnd.
	stream nextPutAll: DateAndTime now printString , ' | ' , aString; lf; close ]
		on: Error do: [ :e |  ]
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
