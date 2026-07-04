"
I am the living image's ear: a localhost-only HTTP listener (port 8807) so
tooling outside the process can update the RUNNING session instead of
refusing (update.sh) or requiring a Playground paste. Endpoints:
  GET  /ping    -- liveness check
  POST /update  -- AgentUpdater updateFromSrc (reload our packages, migrate
                   on the UI thread, save)
No arbitrary eval is exposed; /update only loads this repository's own src/.
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
	AgentUpdater isInteractive ifFalse: [ ^ nil ].
	(server notNil and: [ server isRunning ]) ifTrue: [ ^ server ].
	server := ZnServer on: self port.
	server bindingAddress: NetNameResolver loopBackAddress.
	server onRequestRespond: [ :request | self handleRequest: request ].
	[ server start ] on: Error do: [ :e | server := nil ].
	^ server
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
	^ ZnResponse notFound: request uri
]
