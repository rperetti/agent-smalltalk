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

{ #category : 'tests' }
AgentSpotlightTest >> testShortPromptRetainsCompactInputHeight [
	| spotlight |
	spotlight := AgentSpotlight new.
	spotlight promptText: 'make a counter'.
	self assert: spotlight inputHeight equals: spotlight defaultInputHeight.
	self deny: spotlight isInputAtMaximumHeight
]

{ #category : 'tests' }
AgentSpotlightTest >> testLongPromptGrowsInputHeightButStopsAtCap [
	| spotlight longPrompt |
	spotlight := AgentSpotlight new.
	longPrompt := String new: 2000 withAll: $x.
	spotlight promptText: longPrompt.
	self assert: spotlight inputHeight equals: spotlight maximumInputHeight.
	self assert: spotlight isInputAtMaximumHeight
]

{ #category : 'tests' }
AgentSpotlightTest >> testClearingPromptShrinksInputHeight [
	| spotlight |
	spotlight := AgentSpotlight new.
	spotlight promptText: (String new: 300 withAll: $x).
	self assert: spotlight inputHeight > spotlight defaultInputHeight.
	spotlight promptText: ''.
	self assert: spotlight inputHeight equals: spotlight defaultInputHeight
]

{ #category : 'tests' }
AgentSpotlightTest >> testWrappedLinesGrowWithoutRewritingPrompt [
	| spotlight prompt |
	spotlight := AgentSpotlight new.
	prompt := (String new: 80 withAll: $x) , String cr
		, (String new: 80 withAll: $y).
	spotlight promptText: prompt.
	self assert: spotlight inputHeight > spotlight defaultInputHeight.
	self assert: (spotlight instVarNamed: #inputField) text asString equals: prompt
]

{ #category : 'tests' }
AgentSpotlightTest >> testTextEditEventResizesWithoutDroppingFocus [
	| spotlight space input |
	spotlight := AgentSpotlight new.
	space := BlSpace new.
	space root addChild: spotlight.
	input := spotlight instVarNamed: #inputField.
	input requestFocus.
	self assert: input hasFocus.
	input text: (String new: 300 withAll: $x) asRopedText.
	input dispatchEvent: (AlbTextEditedEvent new text: input text).
	self assert: spotlight inputHeight > spotlight defaultInputHeight.
	self assert: input hasFocus
]
