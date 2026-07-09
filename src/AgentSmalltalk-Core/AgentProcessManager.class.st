"
I own the lifecycle of background processes started by AgentSmalltalk.
Processes are live objects and therefore get serialized into snapshots; on a
fresh session, continuing an old spotlight request, fact sweep, flash, or
watchdog would run stale compiled code against a new world. AgentSandbox's
session hooks ask me to terminate every known managed process before snapshots
and again on startup.
"
Class {
	#name : 'AgentProcessManager',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentProcessManager class >> managedNames [
	^ #(
		'agent-fact-watcher'
		'agent-flash'
		'agent-remote-boot'
		'agent-remote-watchdog'
		'agent-spotlight-run')
]

{ #category : 'testing' }
AgentProcessManager class >> managesName: aString [
	^ (self managedNames includes: aString)
		or: [ (aString beginsWith: 'agent-widget-')
		or: [ aString beginsWith: 'agent-automation-' ] ]
]

{ #category : 'lifecycle' }
AgentProcessManager class >> terminateAll [
	[ Process allSubInstances do: [ :process |
		(process ~~ Processor activeProcess
			and: [ process isTerminated not
			and: [ self managesName: (process name ifNil: [ '' ]) ] ])
				ifTrue: [
					[ process terminate ] on: Error do: [ :ignored |  ] ] ] ]
		on: Error
		do: [ :ignored |  ]
]
