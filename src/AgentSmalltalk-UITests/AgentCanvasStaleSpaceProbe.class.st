"
Closed-space probe that retains queued work without executing it. It models a
serialized Bloc space whose #isOpened marker survived after its native window.
"
Class {
	#name : 'AgentCanvasStaleSpaceProbe',
	#superclass : 'Object',
	#instVars : [
		'queuedTasks',
		'pulseRequests'
	],
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'initialization' }
AgentCanvasStaleSpaceProbe >> initialize [
	super initialize.
	queuedTasks := OrderedCollection new.
	pulseRequests := 0
]

{ #category : 'testing' }
AgentCanvasStaleSpaceProbe >> isOpened [
	^ true
]

{ #category : 'scheduling' }
AgentCanvasStaleSpaceProbe >> enqueueTask: aTask [
	queuedTasks add: aTask
]

{ #category : 'scheduling' }
AgentCanvasStaleSpaceProbe >> requestNextPulse [
	pulseRequests := pulseRequests + 1
]

{ #category : 'accessing' }
AgentCanvasStaleSpaceProbe >> queuedTasks [
	^ queuedTasks
]

{ #category : 'accessing' }
AgentCanvasStaleSpaceProbe >> pulseRequests [
	^ pulseRequests
]
