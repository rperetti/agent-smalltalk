"
GUI-like canvas double used to prove that a stale Bloc space is not scheduled.
The normal test image is headless, so this overrides that one predicate while
keeping the production liveness checks intact.
"
Class {
	#name : 'AgentCanvasInteractiveTestProbe',
	#superclass : 'AgentCanvas',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'testing' }
AgentCanvasInteractiveTestProbe >> isHeadlessSession [
	^ false
]

{ #category : 'accessing' }
AgentCanvasInteractiveTestProbe >> space: aSpace [
	space := aSpace
]
