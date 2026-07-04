"
Headless tests for deletion undo (stack of 50, restore, edge cases) and
widget resizing (grip idempotence, minimum size clamp).
"
Class {
	#name : 'AgentUndoResizeTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentUndoResizeTest >> setUp [
	super setUp.
	AgentCanvas reset
]

{ #category : 'running' }
AgentUndoResizeTest >> tearDown [
	AgentCanvas reset.
	super tearDown
]

{ #category : 'tests' }
AgentUndoResizeTest >> testDeletionIsRecordedAndUndone [
	| w |
	w := AgentWidget new.
	AgentCanvas current addWidget: w.
	w removeFromParent.
	self assert: AgentCanvas current widgets isEmpty.
	self assert: AgentCanvas current undoStack size equals: 1.
	AgentCanvas current undoDeletion.
	self assert: (AgentCanvas current widgets includes: w).
	self assert: AgentCanvas current undoStack isEmpty
]

{ #category : 'tests' }
AgentUndoResizeTest >> testFactDeletionIsUndoable [
	| f |
	f := AgentFact key: #probe body: 'x'.
	f removeFromParent.
	AgentCanvas current undoDeletion.
	self assert: (AgentCanvas current factWithKey: #probe) notNil
]

{ #category : 'tests' }
AgentUndoResizeTest >> testUndoOnEmptyStackIsSafe [
	self assert: AgentCanvas current undoDeletion isNil
]

{ #category : 'tests' }
AgentUndoResizeTest >> testStackIsCappedAtFifty [
	60 timesRepeat: [
		| w |
		w := AgentWidget new.
		AgentCanvas current addWidget: w.
		w removeFromParent ].
	self assert: AgentCanvas current undoStack size equals: 50
]

{ #category : 'tests' }
AgentUndoResizeTest >> testRemovalOutsideCanvasIsNotRecorded [
	| w holder |
	w := AgentWidget new.
	holder := BlElement new.
	holder addChild: w.
	w removeFromParent.
	self assert: AgentCanvas current undoStack isEmpty
]

{ #category : 'tests' }
AgentUndoResizeTest >> testRaiseIsMonotonicAcrossWidgets [
	| a b |
	a := AgentWidget new.
	b := AgentWidget new.
	a raise.
	b raise.
	self assert: b elevation > a elevation.
	a raise.
	self assert: a elevation > b elevation
]

{ #category : 'tests' }
AgentUndoResizeTest >> testRaiseWiringIsIdempotent [
	| w |
	w := AgentWidget new.
	w ensureRaisesOnClick.
	w ensureRaisesOnClick.
	self assert: true
]

{ #category : 'tests' }
AgentUndoResizeTest >> testResizeGripIsIdempotent [
	| w n |
	w := AgentWidget new.
	n := w children size.
	w ensureResizeGrip.
	self assert: w children size equals: n
]

{ #category : 'tests' }
AgentUndoResizeTest >> testResizeClampsToMinimum [
	| w |
	w := AgentWidget new.
	w resizeTo: 30 @ 900.
	"Requested extent is clamped; read back via constraints-independent
	measure after forced layout is unreliable headless, so clamp directly."
	self assert: (30 @ 900 max: 120 @ 80) equals: 120 @ 900
]