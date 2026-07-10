"
Headless tests for phase 3: selection state, Selection globals, scoped
context rendering, and pan/zoom math. All run against the detached-content
canvas (no display).
"
Class {
	#name : 'AgentCanvasSelectionTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentCanvasSelectionTest >> setUp [
	super setUp.
	AgentCanvas reset.
	self removeSelectionGlobals
]

{ #category : 'running' }
AgentCanvasSelectionTest >> tearDown [
	AgentCanvas reset.
	self removeSelectionGlobals.
	super tearDown
]

{ #category : 'running' }
AgentCanvasSelectionTest >> removeSelectionGlobals [
	| n |
	n := 1.
	[ Smalltalk globals includesKey: ('Selection' , n printString) asSymbol ] whileTrue: [
		Smalltalk globals removeKey: ('Selection' , n printString) asSymbol.
		n := n + 1 ].
	Smalltalk globals removeKey: #SelectionAll ifAbsent: [  ]
]

{ #category : 'running' }
AgentCanvasSelectionTest >> newWidget [
	| w |
	w := AgentWidget new.
	AgentCanvas current addWidget: w.
	^ w
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testSelectBindsLiveGlobals [
	| a b |
	a := self newWidget.
	b := self newWidget.
	AgentCanvas current selectWidgets: { a. b }.
	self assert: (Smalltalk globals at: #Selection1) identicalTo: a.
	self assert: (Smalltalk globals at: #Selection2) identicalTo: b.
	self assert: (Smalltalk globals at: #SelectionAll) equals: { a. b }
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testReselectRemovesStaleGlobals [
	| a b |
	a := self newWidget.
	b := self newWidget.
	AgentCanvas current selectWidgets: { a. b }.
	AgentCanvas current selectWidgets: { b }.
	self assert: (Smalltalk globals at: #Selection1) identicalTo: b.
	self deny: (Smalltalk globals includesKey: #Selection2).
	self assert: (Smalltalk globals at: #SelectionAll) equals: { b }
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testClearSelectionKeepsGlobalsForFollowUps [
	| a |
	a := self newWidget.
	AgentCanvas current selectWidgets: { a }.
	AgentCanvas current clearSelection.
	self assert: AgentCanvas current selectedWidgets isEmpty.
	self assert: (Smalltalk globals at: #Selection1) identicalTo: a
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testSelectionScopesContext [
	| a context |
	a := self newWidget.
	self newWidget.
	self newWidget.
	AgentCanvas current selectWidgets: { a }.
	context := AgentCanvas current contextDescription.
	self assert: (context includesSubstring: '## Selected widgets').
	self assert: (context includesSubstring: 'Selection1 = AgentWidget').
	self assert: (context includesSubstring: 'omitted').
	self deny: (context includesSubstring: '## Widgets on the canvas')
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testEmptySelectionShowsFullCanvas [
	self newWidget.
	self assert: (AgentCanvas current contextDescription
		includesSubstring: '## Widgets on the canvas')
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testWorldPointMath [
	| canvas |
	canvas := AgentCanvas current.
	canvas zoomAt: 0 @ 0 by: 2.
	self assert: canvas zoom equals: 2.
	"screen = pan + world*zoom; pan stayed 0@0 for cursor at origin"
	self assert: (canvas worldPointFrom: 30 @ 30) equals: 15 @ 15
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testZoomIsClamped [
	| canvas |
	canvas := AgentCanvas current.
	10 timesRepeat: [ canvas zoomAt: 0 @ 0 by: 2 ].
	self assert: canvas zoom equals: 3.0.
	20 timesRepeat: [ canvas zoomAt: 0 @ 0 by: 0.5 ].
	self assert: canvas zoom equals: 0.25
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testHighlightRestoresClassSpecificBorder [
	| w f |
	w := self newWidget.
	f := AgentFact key: #probe body: 'x'.
	AgentCanvas current selectWidgets: { w. f }.
	AgentCanvas current clearSelection.
	self assert: w border equals: w defaultBorder.
	self assert: f border equals: f defaultBorder
]

{ #category : 'tests' }
AgentCanvasSelectionTest >> testStaleSpaceDoesNotQueueBackgroundWidgetUpdate [
	| canvas space didRun |
	AgentRemote disable.
	canvas := AgentCanvasInteractiveTestProbe new.
	space := AgentCanvasStaleSpaceProbe new.
	canvas space: space.
	AgentCanvas instVarNamed: #current put: canvas.
	[
		self assert: canvas hasSpace.
		self assert: canvas isDisplayed.
		self deny: canvas isInteractive.
		self deny: canvas isOpen.
		didRun := false.
		AgentWidget new runOnUiThreadSafely: [ didRun := true ].
		self assert: didRun.
		self assert: space queuedTasks isEmpty.
		self assert: space pulseRequests equals: 0 ]
		ensure: [ AgentRemote disable. AgentCanvas reset ]
]
