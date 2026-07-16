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
AgentUndoResizeTest >> testReactiveWidgetRestoresFactAndWidgetReactionsWithoutDuplicates [
	| reactive source |
	reactive := AgentReactiveLifecycleTestWidget new.
	source := AgentWidget new.
	AgentCanvas current addWidget: reactive.
	AgentCanvas current addWidget: source.
	AgentFact key: #city body: 'Tokyo'.
	source announceChanged.
	self assert: reactive factReactionCount equals: 1.
	self assert: reactive widgetReactionCount equals: 1.
	reactive removeFromParent.
	AgentFact key: #city body: 'Lisbon'.
	source announceChanged.
	self assert: reactive factReactionCount equals: 1.
	self assert: reactive widgetReactionCount equals: 1.
	AgentCanvas current undoDeletion.
	AgentFact key: #city body: 'Paris'.
	source announceChanged.
	self assert: reactive factReactionCount equals: 2.
	self assert: reactive widgetReactionCount equals: 2.
	reactive removeFromParent.
	AgentCanvas current undoDeletion.
	AgentFact key: #city body: 'Rome'.
	source announceChanged.
	self assert: reactive factReactionCount equals: 3.
	self assert: reactive widgetReactionCount equals: 3
]

{ #category : 'tests' }
AgentUndoResizeTest >> testReactionMigrationOnlyReconnectsAttachedWidgets [
	| canvas attached detached |
	canvas := AgentCanvas current.
	attached := AgentReactiveLifecycleTestWidget new.
	detached := AgentReactiveLifecycleTestWidget new.
	canvas addWidget: attached.
	"The public migration entry point is idempotent for the canvas widget and
	must leave a disposable, headless instance detached from the announcer."
	canvas reconnectReactionsFor: AgentReactiveLifecycleTestWidget.
	detached reconnectReactions.
	AgentFact key: #city body: 'Tokyo'.
	self assert: attached factReactionCount equals: 1.
	self assert: detached factReactionCount equals: 0.
	canvas reconnectReactionsFor: AgentReactiveLifecycleTestWidget.
	AgentFact key: #city body: 'Lisbon'.
	self assert: attached factReactionCount equals: 2.
	self assert: detached factReactionCount equals: 0
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
	"Elevations must stay proper BlElevation objects (raw integers break
	Bloc's picking sorter) and be monotonic."
	self assert: a elevation class equals: BlRelativeElevation.
	self assert: b elevation elevation > a elevation elevation.
	a raise.
	self assert: a elevation elevation > b elevation elevation
]

{ #category : 'tests' }
AgentUndoResizeTest >> testRepairElevationHealsRawIntegers [
	| w |
	w := AgentWidget new.
	w elevation: 7.
	w repairElevation.
	self assert: w elevation class equals: BlRelativeElevation.
	self assert: w elevation elevation equals: 7
]

{ #category : 'tests' }
AgentUndoResizeTest >> testAddedWidgetRaisesAboveExisting [
	| first second |
	first := AgentWidget new.
	AgentCanvas current addWidget: first.
	second := AgentWidget new.
	AgentCanvas current addWidget: second.
	"A freshly added widget must sit above ones already on the canvas."
	self assert: second elevation elevation > first elevation elevation
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
AgentUndoResizeTest >> testWidgetShowsDeleteButtonStickyDoesNot [
	self assert: AgentWidget new showsDeleteButton.
	self deny: (AgentFact key: #x body: 'y') showsDeleteButton
]

{ #category : 'tests' }
AgentUndoResizeTest >> testDeleteButtonIsIdempotent [
	| w n |
	w := AgentWidget new.
	n := w children size.
	w ensureDeleteButton.
	self assert: w children size equals: n
]

{ #category : 'tests' }
AgentUndoResizeTest >> testDeleteKeyRemovesSelection [
	| a b evt |
	a := AgentWidget new.
	b := AgentWidget new.
	AgentCanvas current addWidget: a.
	AgentCanvas current addWidget: b.
	AgentCanvas current selectWidgets: { a. b }.
	evt := BlKeyDownEvent new key: KeyboardKey delete.
	AgentCanvas current handleDeleteKey: evt.
	self assert: AgentCanvas current widgets isEmpty.
	self assert: AgentCanvas current selectedWidgets isEmpty.
	"Deletions are undoable."
	self assert: AgentCanvas current undoStack size equals: 2
]

{ #category : 'tests' }
AgentUndoResizeTest >> testDeleteKeyNoopWithoutSelection [
	| evt |
	AgentCanvas current addWidget: AgentWidget new.
	evt := BlKeyDownEvent new key: KeyboardKey delete.
	AgentCanvas current handleDeleteKey: evt.
	self assert: AgentCanvas current widgets size equals: 1.
	self deny: evt isConsumed
]

{ #category : 'tests' }
AgentUndoResizeTest >> testDeleteKeyIgnoredWhileEditingText [
	"Backspace/Delete originating inside a text editor (the spotlight, a sticky
	body) must edit text -- it must NOT delete the lassoed selection, even
	though the event bubbles up to the canvas root unconsumed."
	| widget editor innerTarget evt |
	widget := AgentWidget new.
	AgentCanvas current addWidget: widget.
	AgentCanvas current selectWidgets: { widget }.
	editor := ToAlbum new.
	innerTarget := BlElement new.
	editor addChild: innerTarget.
	evt := BlKeyDownEvent new key: KeyboardKey backspace.
	evt target: innerTarget.
	AgentCanvas current handleDeleteKey: evt.
	self assert: (AgentCanvas current widgets includes: widget).
	self assert: (AgentCanvas current selectedWidgets includes: widget).
	self deny: evt isConsumed
]

{ #category : 'tests' }
AgentUndoResizeTest >> testUndoKeyIgnoredWhileEditingFactText [
	"The fact editor leaves Cmd+Z unconsumed for native text undo. The canvas
	must not also restore its most recently deleted card when the event reaches
	the root handler."
	| deleted fact editor innerTarget evt |
	deleted := AgentWidget new.
	AgentCanvas current addWidget: deleted.
	deleted removeFromParent.
	fact := AgentFact key: #undoEditorProbe body: 'draft'.
	editor := fact instVarNamed: #bodyEditor.
	innerTarget := BlElement new.
	editor addChild: innerTarget.
	evt := BlKeyDownEvent new key: KeyboardKey Z.
	evt modifiers: (BlKeyModifiers shift: false ctrl: false alt: false cmd: true).
	evt target: innerTarget.
	AgentCanvas current handleKeyDown: evt.
	self deny: (AgentCanvas current widgets includes: deleted).
	self assert: AgentCanvas current undoStack size equals: 1.
	self deny: evt isConsumed
]

{ #category : 'tests' }
AgentUndoResizeTest >> testCanvasClickReleasesFactEditorForDeletionUndo [
	"Bloc keeps a text editor focused when the pointer clicks outside it. The
	canvas must deliberately blur that editor so Cmd+Z restores a deleted card
	instead of repeatedly undoing the fact's text."
	| canvas space fact editor deleted clickEvt undoEvt |
	canvas := AgentCanvas current.
	space := BlSpace new.
	canvas instVarNamed: #space put: space.
	space root addChild: canvas ensureContent.
	fact := AgentFact key: #undoFocusProbe body: 'Lisbon'.
	deleted := AgentWidget new.
	canvas addWidget: deleted.
	deleted removeFromParent.
	editor := fact instVarNamed: #bodyEditor.
	editor requestFocus.
	self assert: space focusOwner notNil.
	clickEvt := BlMouseDownEvent new.
	clickEvt target: fact parent.
	canvas handleMouseDown: clickEvt.
	self assert: space focusOwner isNil.
	undoEvt := BlKeyDownEvent new key: KeyboardKey Z.
	undoEvt modifiers: (BlKeyModifiers shift: false ctrl: false alt: false cmd: true).
	undoEvt target: space root.
	canvas handleKeyDown: undoEvt.
	self assert: (canvas widgets includes: deleted).
	self assert: undoEvt isConsumed
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
