"
I am the spatial canvas: a singleton wrapping a Bloc space on which AgentWidgets
live. The content element is pannable (drag empty background) and zoomable
(mouse wheel, around the cursor). Shift+drag draws a lasso: intersected widgets
become the selection -- highlighted, bound to Selection1..N / SelectionAll
globals, and the ONLY widgets serialized into the LLM context (the canvas is
the context window). Click on empty background clears the selection (globals
persist until the next selection, for follow-up requests).
Headless (no space open) I still hold widgets on a detached content element so
the code-generation loop can be exercised without a display.
"
Class {
	#name : 'AgentCanvas',
	#superclass : 'Object',
	#instVars : [
		'space',
		'content',
		'selection',
		'panOffset',
		'zoom',
		'dragMode',
		'dragMoved',
		'dragStart',
		'panStart',
		'lassoElement',
		'pressShift',
		'navWired',
		'rootWired',
		'undoStack',
		'topElevation',
		'announcer',
		'widgetAddVersion'
	],
	#classInstVars : [
		'current'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'accessing' }
AgentCanvas class >> current [
	^ current ifNil: [ current := self new ]
]

{ #category : 'accessing' }
AgentCanvas class >> reunite [
	"Recovery: re-point `current` at the canvas actually shown on screen.
	The singleton is orphaned if `current` is nil'd or replaced while a
	canvas is displayed -- e.g. a unit test's `AgentCanvas reset` run in a
	live session. Displayed widgets then talk to the orphaned instance's
	announcer, so reactions silently break. One call restores routing.
	(Not auto-run in the getter: `space isOpened` can read stale-true in
	headless test runs, which would break test isolation.)"
	| shown |
	shown := self allInstances
		detect: [ :c | c isInteractive ]
		ifNone: [ nil ].
	shown ifNil: [ ^ nil ].
	current := shown.
	"Close any OTHER canvas's window -- an orphaned reset leftover can leave
	an empty second window on screen. Only the shown, reunited canvas survives."
	self allInstances do: [ :c |
		(c ~~ shown and: [ c space notNil ]) ifTrue: [
			[ c space close ] on: Error do: [ :e |  ] ] ].
	^ shown
]

{ #category : 'accessing' }
AgentCanvas class >> isOpen [
	^ current notNil and: [ current isOpen ]
]

{ #category : 'opening' }
AgentCanvas class >> open [
	^ self current open
]

{ #category : 'accessing' }
AgentCanvas class >> reset [
	current := nil
]

{ #category : 'system startup' }
AgentCanvas class >> prepareForQuit [
	"Persist the canvas graph without persisting an open native window.
	Otherwise Bloc resurrects the window during a later --headless launch,
	before AgentSmalltalk's startup hooks can intervene."
	current ifNotNil: [ current prepareForQuit ]
]

{ #category : 'initialization' }
AgentCanvas >> initialize [
	super initialize.
	selection := OrderedCollection new.
	panOffset := 0 @ 0.
	zoom := 1
]

{ #category : 'accessing' }
AgentCanvas >> selection [
	"Lazy: singletons in user images are migrated (slots nil), never re-initialized."
	^ selection ifNil: [ selection := OrderedCollection new ]
]

{ #category : 'testing' }
AgentCanvas >> isOpen [
	"Compatibility alias for callers that need a live UI space. A non-nil
	space can be a serialized, closed leftover, so it is not enough."
	^ self isInteractive
]

{ #category : 'testing' }
AgentCanvas >> hasSpace [
	"The canvas owns a Bloc space object, whether live or stale."
	^ space notNil
]

{ #category : 'testing' }
AgentCanvas >> isDisplayed [
	"Bloc's display marker. It is useful diagnostically, but can be stale
	after image resume and must not by itself justify UI scheduling."
	^ self hasSpace and: [ space isOpened ]
]

{ #category : 'testing' }
AgentCanvas >> isInteractive [
	"A fresh-session proof plus Bloc's display marker means queued UI work
	will pulse. AgentRemote's flag is reset at every boot and enabled only by
	the GUI #open path, so it rejects serialized stale spaces."
	^ self isDisplayed and: [ AgentRemote isEnabled ]
]

{ #category : 'testing' }
AgentCanvas >> isHeadlessSession [
	^ UIManager default isKindOf: NonInteractiveUIManager
]

{ #category : 'system startup' }
AgentCanvas >> prepareForQuit [
	"Detach the persistent content graph from the ephemeral native space.
	The next AgentCanvas open builds a fresh space around the same widgets."
	space ifNil: [ ^ self ].
	content ifNotNil: [ content removeFromParent ].
	[ space close ] on: Error do: [ :ignored |  ].
	space := nil.
	rootWired := nil
]

{ #category : 'accessing' }
AgentCanvas >> space [
	^ space
]

{ #category : 'accessing' }
AgentCanvas >> zoom [
	^ zoom ifNil: [ zoom := 1 ]
]

{ #category : 'accessing' }
AgentCanvas >> panOffset [
	^ panOffset ifNil: [ panOffset := 0 @ 0 ]
]

{ #category : 'private' }
AgentCanvas >> ensureContent [
	content ifNil: [
		content := BlElement new.
		content constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ] ].
	"Transparent, non-clipping transform layer: the visible background lives
	on the space root so panning never reveals a differently-colored void."
	content background: Color transparent.
	content clipChildren: false.
	^ content
]

{ #category : 'opening' }
AgentCanvas >> open [
	"This is a GUI-only entry point (launched via `eval AgentCanvas open`),
	so it is THE place that enables the remote listener -- the one signal
	that reliably means interactive, since every saved flag is poisoned by
	GUI-saved images resumed headless."
	AgentRemote enable.
	space ifNotNil: [
		space isOpened ifTrue: [
			"Bloc auto-restored the saved window at startup: open is a no-op
			for the UI, but session services must still start."
			AgentRemote ensureRunning.
			self startFactWatcher.
			AgentScheduler current start.
			^ self ].
		"Stale space: the image was saved from a headless session (update.sh),
		so the space object outlived its OS window. Rebuild the window around
		the existing content -- widgets and their handlers all survive."
		[ space close ] on: Error do: [ :e |  ].
		content ifNotNil: [ content removeFromParent ].
		space := nil ].
	self ensureContent.
	space := BlSpace new.
	space toTheme: ToBeeTheme new.
	space title: 'Agent Canvas'.
	space extent: 1280 @ 840.
	space root background: (Color fromHexString: 'F4F1E8').
	space root addChild: content.
	self wireKeyboard.
	self wireNavigation.
	AgentRemote ensureRunning.
	self startFactWatcher.
	AgentScheduler current start.
	space show
]

{ #category : 'navigation' }
AgentCanvas >> wireNavigation [
	"Attach THIN handlers that only delegate: behavior then updates via
	method recompilation. Gestures use DRAG events: Bloc delivers them to
	the originating element for the whole gesture, so widgets under the
	moving cursor cannot eat them (bubbled mouse-moves get consumed by
	widget internals -- the lasso 'invisible wall'). Version 2 wiring;
	the isConsumed guards prevent double handling next to v1 leftovers."
	navWired == 2 ifFalse: [
		self wireGesturesOn: content.
		navWired := 2 ].
	(space notNil and: [ rootWired ~~ 2 ]) ifTrue: [
		self wireGesturesOn: space root.
		rootWired := 2 ]
]

{ #category : 'navigation' }
AgentCanvas >> wireGesturesOn: anElement [
	anElement addEventHandlerOn: BlMouseDownEvent do: [ :evt | self handleMouseDown: evt ].
	anElement addEventHandlerOn: BlDragStartEvent do: [ :evt | self handleDragStart: evt ].
	anElement addEventHandlerOn: BlDragEvent do: [ :evt | self handleDrag: evt ].
	anElement addEventHandlerOn: BlDragEndEvent do: [ :evt | self handleDragEnd: evt ].
	anElement addEventHandlerOn: BlClickEvent do: [ :evt | self handleCanvasClick: evt ].
	anElement addEventHandlerOn: BlMouseWheelEvent do: [ :evt | self handleWheel: evt ]
]

{ #category : 'navigation' }
AgentCanvas >> migrateAfterUpdate [
	"Run by scripts/update.st after reloading code into a living image:
	repair persistent widgets even when the image is closed, then perform
	session setup that only makes sense for an already-open space."
	self widgets do: [ :w |
		w ensureResizeGrip.
		w ensureRaisesOnClick.
		w refreshDeleteButton.
		w repairElevation.
		"Redesign: rebuild existing stickies (fact/note/system) into the new
		chip chrome. Guarded so one card that fails to rebuild cannot abort the
		migration -- and the failure surfaces as a system message instead of
		vanishing, so a silent no-op restyle is diagnosable on the canvas."
		(w isKindOf: AgentSticky) ifTrue: [
			[ w repairChrome ]
				on: Error
				do: [ :e |
					[ AgentSystemMessage
						post: 'Card restyle failed in ' , w class name , ': '
							, e class name , ' -- '
							, (e messageText ifNil: [ '(no message)' ])
						key: ('cardRepairFailure-' , w class name) asSymbol ]
						on: Error do: [ :ignored |  ] ] ].
		(w isKindOf: AgentToolCard) ifTrue: [ w repairLayout ].
		(w isKindOf: AgentAutomationCard) ifTrue: [ w repairLayout ] ].
	self isInteractive ifFalse: [ ^ self ].
	self ensureContent.
	space root background: (Color fromHexString: 'F4F1E8').
	self wireKeyboard.
	self wireNavigation.
	self pruneStaleSubscriptions.
	self startFactWatcher.
	AgentScheduler current start.
	AgentRemote ensureRunning
]

{ #category : 'navigation' }
AgentCanvas >> wireKeyboard [
	"One thin key handler on the root. Old key handlers (including inline
	blocks from earlier versions) are removed first, so this is idempotent
	and safe to run on every migration. The filter only matches plain
	BlEventHandlers for key-down; listener-style handlers are untouched."
	space ifNil: [ ^ self ].
	space root removeEventHandlersSuchThat: [ :h |
		(h respondsTo: #eventClass) and: [ h eventClass == BlKeyDownEvent ] ].
	space root addEventHandlerOn: BlKeyDownEvent do: [ :evt | self handleKeyDown: evt ]
]

{ #category : 'navigation' }
AgentCanvas >> handleKeyDown: evt [
	| primary |
	evt isConsumed ifTrue: [ ^ self ].
	"Delete/Backspace (no modifier) removes the selection -- handle before
	the modifier gate below."
	self handleDeleteKey: evt.
	evt isConsumed ifTrue: [ ^ self ].
	"Text-editor key events bubble to the canvas unconsumed. Keep canvas
	shortcuts out of that stream so Cmd/Ctrl+Z remains the editor's native undo
	(and Cmd/Ctrl+Enter cannot open the spotlight while typing)."
	(self isTextEditingTarget: evt) ifTrue: [ ^ self ].
	primary := evt modifiers isCmd or: [ evt modifiers isCtrl ].
	primary ifFalse: [ ^ self ].
	evt key = KeyboardKey enter ifTrue: [
		evt consume.
		^ AgentSpotlight openOn: self ].
	(evt key = KeyboardKey Z and: [ evt modifiers isShift not ]) ifTrue: [
		evt consume.
		self undoDeletion ]
]

{ #category : 'navigation' }
AgentCanvas >> handleDeleteKey: evt [
	"Delete/Backspace on the canvas removes the current selection (undoable
	via Cmd+Z). Guarded on a non-empty selection so a stray keypress with
	nothing selected does nothing. Text editors (the spotlight, a sticky body)
	do NOT consume these keys -- the BlKeyDownEvent bubbles up to the space
	root unconsumed -- so we must inspect the event's origin ourselves: a
	keystroke from inside an editor edits text and must not delete widgets."
	evt isConsumed ifTrue: [ ^ self ].
	(evt key = KeyboardKey delete or: [ evt key = KeyboardKey backspace ])
		ifFalse: [ ^ self ].
	(self isTextEditingTarget: evt) ifTrue: [ ^ self ].
	self selection ifEmpty: [ ^ self ].
	evt consume.
	self selection asArray do: [ :w | w removeFromParent ].
	self clearSelection ]

{ #category : 'navigation' }
AgentCanvas >> isTextEditingTarget: evt [
	"True when a key event originates inside a text editor (ToAlbum) or the
	spotlight. Their native text commands (including Backspace/Delete and
	Cmd/Ctrl+Z) must not trigger canvas shortcuts. Walks up from the event
	target (the focused element), since the event bubbles to the root handler
	unconsumed."
	| node |
	node := evt target.
	[ node notNil ] whileTrue: [
		((node isKindOf: ToAlbum) or: [ node isKindOf: AgentSpotlight ])
			ifTrue: [ ^ true ].
		node := node parent ].
	^ false ]

{ #category : 'reactions' }
AgentCanvas >> announcePendingFactEdits [
	"Announce facts whose bodies drifted from their last announcement --
	the safety net for manual edits when focus events don't deliver."
	self facts do: [ :f |
		f hasUnannouncedEdit ifTrue: [
			[ f announceFactChanged ] on: Error do: [ :e |  ] ] ]
]

{ #category : 'reactions' }
AgentCanvas >> startFactWatcher [
	"GUI-only background sweep: manual sticky edits announce within ~3s
	even if the blur event never fires (the Album focus risk the phase 4
	spec flagged). Named process, so saves/reopens cannot duplicate it."
	self isHeadlessSession ifTrue: [ ^ self ].
	(Process allSubInstances anySatisfy: [ :p |
		p name = 'agent-fact-watcher' and: [ p isTerminated not ] ])
		ifTrue: [ ^ self ].
	[ [ true ] whileTrue: [
		3 seconds wait.
		[ self announcePendingFactEdits ] on: Error do: [ :e |  ] ] ]
		forkNamed: 'agent-fact-watcher'
]

{ #category : 'reactions' }
AgentCanvas >> pruneStaleSubscriptions [
	"Unsubscribe any AgentWidget not currently on the canvas. Off-canvas
	widgets must never react -- a ghost subscriber (leftover from a canvas
	reset, a class reshape, or a removal that skipped removeFromParent) firing
	a reaction against stale state crashes the whole UI. Belt-and-suspenders
	on top of removeFromParent's own unsubscribe."
	| live widgetClass |
	widgetClass := Smalltalk globals at: #AgentWidget ifAbsent: [ ^ self ].
	live := self widgets asIdentitySet.
	widgetClass allSubInstances do: [ :w |
		(live includes: w) ifFalse: [
			[ self announcer unsubscribe: w ] on: Error do: [ :e |  ] ] ]
]

{ #category : 'reactions' }
AgentCanvas >> announcer [
	"The canvas-wide announcer: FactChanged, WidgetChanged. Lazy for
	migrated singletons."
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'z order' }
AgentCanvas >> nextTopElevation [
	"Monotonic: the most recently pressed widget paints on top. Lazy for
	migrated singletons."
	^ topElevation := (topElevation ifNil: [ 0 ]) + 1
]

{ #category : 'undo' }
AgentCanvas >> undoStack [
	"Lazy (singletons in user images migrate with nil slots). Survives image
	save/reopen: undoing yesterday's deletion is a living-image privilege."
	^ undoStack ifNil: [ undoStack := OrderedCollection new ]
]

{ #category : 'undo' }
AgentCanvas >> containsWidget: aWidget [
	^ content notNil and: [ aWidget parent == content ]
]

{ #category : 'undo' }
AgentCanvas >> recordDeletion: aWidget [
	self undoStack addLast: aWidget.
	[ self undoStack size > 50 ] whileTrue: [ self undoStack removeFirst ]
]

{ #category : 'undo' }
AgentCanvas >> undoDeletion [
	"Restore the most recently deleted widget. Entries whose restore fails
	(e.g. instance of a since-removed, broken class) are discarded."
	| w |
	self undoStack isEmpty ifTrue: [ ^ nil ].
	w := self undoStack removeLast.
	[ w parent isNil ifTrue: [
		self addWidget: w.
		w restoredToCanvas ] ]
		on: Error
		do: [ :e | ^ self undoDeletion ].
	^ w
]

{ #category : 'navigation' }
AgentCanvas >> handleMouseDown: evt [
	"Record press context only. NOT consumed: Bloc must still synthesize
	the click and drag gestures from this press. Shift is captured here
	because drag events may not carry key modifiers. Bloc deliberately retains
	text-editor focus on an outside click; canvas gestures must explicitly release
	it so the next Cmd/Ctrl+Z addresses deletion undo rather than text undo."
	(evt target == content or: [ space notNil and: [ evt target == space root ] ])
		ifFalse: [ pressShift := nil. ^ self ].
	self releaseFocusForCanvasClick.
	self removeLasso.
	pressShift := evt modifiers isShift.
	dragMoved := false
]

{ #category : 'navigation' }
AgentCanvas >> releaseFocusForCanvasClick [
	"An empty-canvas click is an intentional exit from text editing. Bloc's
	default focus processor does not blur an editor merely because the pointer
	moved outside it, which leaves native Cmd/Ctrl+Z active indefinitely."
	| focusOwner |
	space ifNil: [ ^ self ].
	focusOwner := space focusOwner.
	focusOwner ifNotNil: [ focusOwner loseFocus ]
]

{ #category : 'navigation' }
AgentCanvas >> handleMouseMove: evt [
	"Gutted (v2 gestures use drag events); kept because v1 sessions still
	have handlers delegating here."
]

{ #category : 'navigation' }
AgentCanvas >> handleMouseUp: evt [
	"Gutted (v2 gestures use drag events); kept for v1 handler leftovers."
]

{ #category : 'navigation' }
AgentCanvas >> handleDragStart: evt [
	evt isConsumed ifTrue: [ ^ self ].
	(evt target == content or: [ space notNil and: [ evt target == space root ] ])
		ifFalse: [ ^ self ].
	pressShift ifNil: [ ^ self ].
	evt consume.
	dragStart := evt position.
	dragMoved := true.
	pressShift
		ifTrue: [
			dragMode := #lasso.
			self showLassoAt: evt position ]
		ifFalse: [
			dragMode := #pan.
			panStart := self panOffset ]
]

{ #category : 'navigation' }
AgentCanvas >> handleDrag: evt [
	evt isConsumed ifTrue: [ ^ self ].
	dragMode ifNil: [ ^ self ].
	evt consume.
	dragMode = #pan
		ifTrue: [
			panOffset := panStart + (evt position - dragStart).
			self applyTransform ]
		ifFalse: [ self updateLassoTo: evt position ]
]

{ #category : 'navigation' }
AgentCanvas >> handleDragEnd: evt [
	evt isConsumed ifTrue: [ ^ self ].
	dragMode ifNil: [ ^ self ].
	evt consume.
	dragMode = #lasso ifTrue: [ self finishLassoAt: evt position ].
	dragMode := nil.
	pressShift := nil
]

{ #category : 'navigation' }
AgentCanvas >> handleCanvasClick: evt [
	"A plain click (no drag happened) on empty background clears the
	selection. dragMoved suppresses the click Bloc may synthesize right
	after a drag, which would instantly clear a fresh lasso."
	evt isConsumed ifTrue: [ ^ self ].
	(evt target == content or: [ space notNil and: [ evt target == space root ] ])
		ifFalse: [ ^ self ].
	dragMoved == true ifTrue: [ dragMoved := false. ^ self ].
	evt consume.
	self clearSelection
]

{ #category : 'navigation' }
AgentCanvas >> handleWheel: evt [
	"Zoom only with Shift held: the plain wheel stays free for scrolling
	text inside widgets. macOS converts Shift+vertical scroll into a
	HORIZONTAL scroll, so read whichever axis actually moved."
	| delta |
	evt isConsumed ifTrue: [ ^ self ].
	evt modifiers isShift ifFalse: [ ^ self ].
	evt consume.
	delta := evt vector y abs >= evt vector x abs
		ifTrue: [ evt vector y ]
		ifFalse: [ evt vector x ].
	delta > 0 ifTrue: [ self zoomAt: evt position by: 1.1 ].
	delta < 0 ifTrue: [ self zoomAt: evt position by: 1 / 1.1 ]
]

{ #category : 'navigation' }
AgentCanvas >> applyTransform [
	"Screen point = panOffset + (world point * zoom)."
	content ifNil: [ ^ self ].
	content transformDo: [ :t |
		t topLeftOrigin.
		t translateBy: self panOffset.
		t scaleBy: self zoom ]
]

{ #category : 'navigation' }
AgentCanvas >> worldPointFrom: aScreenPoint [
	^ (aScreenPoint - self panOffset) / self zoom
]

{ #category : 'navigation' }
AgentCanvas >> zoomAt: aScreenPoint by: factor [
	| newZoom |
	newZoom := ((self zoom * factor) max: 0.25) min: 3.0.
	newZoom = self zoom ifTrue: [ ^ self ].
	"Keep the world point under the cursor fixed."
	panOffset := aScreenPoint - ((self worldPointFrom: aScreenPoint) * newZoom).
	zoom := newZoom.
	self applyTransform
]

{ #category : 'selection' }
AgentCanvas >> showLassoAt: aPoint [
	lassoElement := BlElement new.
	lassoElement background: ((Color fromHexString: '4A90D9') alpha: 0.15).
	lassoElement border: (BlBorder paint: (Color fromHexString: '4A90D9') width: 1).
	"The lasso must never steal mouse events from the canvas underneath --
	otherwise the mouse-up lands on the lasso and it is never removed."
	lassoElement preventMouseEvents.
	lassoElement position: aPoint.
	lassoElement extent: 1 @ 1.
	space ifNotNil: [ space root addChild: lassoElement ]
]

{ #category : 'selection' }
AgentCanvas >> removeLasso [
	lassoElement ifNotNil: [
		lassoElement removeFromParent.
		lassoElement := nil ]
]

{ #category : 'selection' }
AgentCanvas >> updateLassoTo: aPoint [
	lassoElement ifNil: [ ^ self ].
	lassoElement position: (dragStart min: aPoint).
	lassoElement extent: (dragStart max: aPoint) - (dragStart min: aPoint)
]

{ #category : 'selection' }
AgentCanvas >> finishLassoAt: aPoint [
	| worldRect hits |
	self removeLasso.
	worldRect := (self worldPointFrom: (dragStart min: aPoint))
		corner: (self worldPointFrom: (dragStart max: aPoint)).
	hits := self widgets select: [ :w |
		worldRect intersects: (w position extent: w extent) ].
	self selectWidgets: hits
]

{ #category : 'selection' }
AgentCanvas >> selectedWidgets [
	^ self selection
]

{ #category : 'selection' }
AgentCanvas >> selectWidgets: aCollection [
	self selection do: [ :w | w unhighlight ].
	selection := aCollection asOrderedCollection.
	selection do: [ :w | w highlightSelected ].
	selection ifNotEmpty: [ self bindSelectionGlobals ]
]

{ #category : 'selection' }
AgentCanvas >> clearSelection [
	"Highlights and scoping clear; Selection globals persist until the next
	selection so follow-up requests can keep referencing the objects."
	self selection do: [ :w | w unhighlight ].
	selection := OrderedCollection new
]

{ #category : 'selection' }
AgentCanvas >> bindSelectionGlobals [
	| n |
	n := 1.
	[ Smalltalk globals includesKey: ('Selection' , n printString) asSymbol ] whileTrue: [
		Smalltalk globals removeKey: ('Selection' , n printString) asSymbol.
		n := n + 1 ].
	selection doWithIndex: [ :w :i |
		Smalltalk globals at: ('Selection' , i printString) asSymbol put: w ].
	Smalltalk globals at: #SelectionAll put: selection asArray
]

{ #category : 'widgets' }
AgentCanvas >> addWidget: aWidget [
	"In a live GUI the add must happen on the UI thread (enqueue). In a
	non-interactive session (headless scripts against a GUI-saved image)
	the space never pulses, so the queue would never drain -- and with no
	competing UI thread, adding directly is safe."
	self ensureContent.
	"Record intent synchronously, before a GUI enqueue. The gateway uses
	this monotonic version to distinguish a pure-text answer from a run
	that created a widget, without racing the next Bloc pulse."
	widgetAddVersion := self widgetAddVersion + 1.
	"Raise on add so a freshly created widget is never hidden behind ones
	already raised by click-to-front -- creations always land visible."
	(aWidget isKindOf: AgentWidget) ifTrue: [ aWidget raise ].
	self isInteractive
		ifTrue: [ space enqueueTask: (BlTaskAction new action: [
			content addChild: aWidget.
			(aWidget respondsTo: #addedToCanvas) ifTrue: [ aWidget addedToCanvas ] ]) ]
		ifFalse: [
			content addChild: aWidget.
			(aWidget respondsTo: #addedToCanvas) ifTrue: [ aWidget addedToCanvas ] ]
]

{ #category : 'widgets' }
AgentCanvas >> widgetAddVersion [
	"Lazy for canvases migrated from images created before this slot."
	^ widgetAddVersion ifNil: [ widgetAddVersion := 0 ]
]

{ #category : 'widgets' }
AgentCanvas >> widgets [
	content ifNil: [ ^ #() ].
	^ content children asArray select: [ :c | c isKindOf: AgentWidget ]
]

{ #category : 'widgets' }
AgentCanvas >> facts [
	^ self widgets select: [ :w | w isKindOf: AgentFact ]
]

{ #category : 'widgets' }
AgentCanvas >> toolWidgets [
	^ self widgets reject: [ :w | w isKindOf: AgentFact ]
]

{ #category : 'widgets' }
AgentCanvas >> factWithKey: aSymbol [
	^ self facts detect: [ :f | f key = aSymbol ] ifNone: [ nil ]
]

{ #category : 'widgets' }
AgentCanvas >> notes [
	^ self widgets select: [ :w | w isKindOf: AgentNote ]
]

{ #category : 'widgets' }
AgentCanvas >> systemMessages [
	^ self widgets select: [ :w | w isKindOf: AgentSystemMessage ]
]

{ #category : 'widgets' }
AgentCanvas >> contextWidgets [
	"What the full-canvas context lists: notes, system messages, and tool
	cards stay out unless lassoed. Tool cards are meta -- the tools they
	front are listed under '## Capabilities you've built' instead."
	^ self toolWidgets reject: [ :w |
		(w isKindOf: AgentNote)
			or: [ (w isKindOf: AgentSystemMessage)
			or: [ (w isKindOf: AgentToolCard)
			or: [ w isKindOf: AgentAutomationCard ] ] ] ]
]

{ #category : 'agent context' }
AgentCanvas >> contextDescription [
	^ String streamContents: [ :s |
		s << '## Known facts'.
		s cr.
		self facts
			ifEmpty: [ s << '(none yet)'. s cr ]
			ifNotEmpty: [ :fs |
				fs do: [ :f | s << '- ' << f describe. s cr ] ].
		s cr.
		self selection
			ifEmpty: [ self fullWidgetsOn: s ]
			ifNotEmpty: [ self selectedWidgetsOn: s ] ]
]

{ #category : 'agent context' }
AgentCanvas >> fullWidgetsOn: s [
	s << '## Widgets on the canvas'.
	s cr.
	self contextWidgets
		ifEmpty: [ s << '(the canvas is empty)'. s cr ]
		ifNotEmpty: [ :ws |
			ws do: [ :w |
				s << '- ' << w class name << ' at ' << w position printString
					<< ' -- ' << w describe.
				s cr ] ]
]

{ #category : 'agent context' }
AgentCanvas >> selectedWidgetsOn: s [
	s << '## Selected widgets (the user lassoed these -- the request is about THEM)'.
	s cr.
	selection doWithIndex: [ :w :i |
		s << '- Selection' << i printString << ' = ' << w class name
			<< ' -- ' << w describe.
		s cr.
		s << '    slots: ' << w class instVarNames printString
			<< '  selectors: ' << w class selectors asSortedCollection asArray printString.
		s cr ].
	s << '(These are live objects bound to the globals Selection1..'
		<< selection size printString
		<< ' and SelectionAll. Other widgets exist but are omitted from context.)'.
	s cr
]
