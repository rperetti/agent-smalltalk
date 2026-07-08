"
Headless tests for the spotlight's in-flight guard and cancellation lifecycle.
"
Class {
	#name : 'AgentSpotlightTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'tests' }
AgentSpotlightTest >> testCancelTerminatesRunAndClearsBusyState [
	| spotlight process blocker |
	spotlight := AgentSpotlight new.
	blocker := Semaphore new.
	process := [ blocker wait ] forkNamed: 'agent-spotlight-run'.
	spotlight instVarNamed: #running put: true.
	spotlight instVarNamed: #runProcess put: process.
	spotlight cancel.
	self deny: spotlight isRunning.
	self assert: process isTerminated
]

{ #category : 'tests' }
AgentSpotlightTest >> testSubmitWhileRunningDoesNotStartAnotherProcess [
	| spotlight process blocker |
	spotlight := AgentSpotlight new.
	blocker := Semaphore new.
	process := [ blocker wait ] forkNamed: 'agent-spotlight-run'.
	[
		spotlight instVarNamed: #running put: true.
		spotlight instVarNamed: #runProcess put: process.
		spotlight submit.
		self assert: (spotlight instVarNamed: #runProcess) identicalTo: process ]
	ensure: [
		[ process terminate ] on: Error do: [ :ignored |  ] ]
]
