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
		'navWired'
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
	^ space notNil
]

{ #category : 'testing' }
AgentCanvas >> isHeadlessSession [
	^ UIManager default isKindOf: NonInteractiveUIManager
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
		content background: (Color fromHexString: 'F4F1E8').
		content constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ] ].
	^ content
]

{ #category : 'opening' }
AgentCanvas >> open [
	space ifNotNil: [ ^ self ].
	self ensureContent.
	space := BlSpace new.
	space toTheme: ToBeeTheme new.
	space title: 'Agent Canvas'.
	space extent: 1280 @ 840.
	space root addChild: content.
	space root addEventHandlerOn: BlKeyDownEvent do: [ :evt |
		(evt key = KeyboardKey enter and: [ evt modifiers isCmd or: [ evt modifiers isCtrl ] ])
			ifTrue: [ AgentSpotlight openOn: self ] ].
	self wireNavigation.
	space show
]

{ #category : 'navigation' }
AgentCanvas >> wireNavigation [
	"Attach THIN handlers that only delegate: behavior then updates via
	method recompilation, no rewiring needed. Idempotent via navWired."
	navWired == true ifTrue: [ ^ self ].
	content addEventHandlerOn: BlMouseDownEvent do: [ :evt | self handleMouseDown: evt ].
	content addEventHandlerOn: BlMouseMoveEvent do: [ :evt | self handleMouseMove: evt ].
	content addEventHandlerOn: BlMouseUpEvent do: [ :evt | self handleMouseUp: evt ].
	content addEventHandlerOn: BlMouseWheelEvent do: [ :evt | self handleWheel: evt ].
	navWired := true
]

{ #category : 'navigation' }
AgentCanvas >> migrateAfterUpdate [
	"Run by scripts/update.st after reloading code into a living image:
	setup steps that open-time wiring cannot deliver to already-open spaces."
	self isOpen ifTrue: [ self wireNavigation ]
]

{ #category : 'navigation' }
AgentCanvas >> handleMouseDown: evt [
	evt target == content ifFalse: [ ^ self ].
	evt consume.
	dragStart := evt position.
	dragMoved := false.
	evt modifiers isShift
		ifTrue: [
			dragMode := #lasso.
			self showLassoAt: evt position ]
		ifFalse: [
			dragMode := #pan.
			panStart := self panOffset ]
]

{ #category : 'navigation' }
AgentCanvas >> handleMouseMove: evt [
	dragMode ifNil: [ ^ self ].
	evt consume.
	dragMoved := true.
	dragMode = #pan
		ifTrue: [
			panOffset := panStart + (evt position - dragStart).
			self applyTransform ]
		ifFalse: [ self updateLassoTo: evt position ]
]

{ #category : 'navigation' }
AgentCanvas >> handleMouseUp: evt [
	dragMode ifNil: [ ^ self ].
	evt consume.
	dragMode = #lasso
		ifTrue: [ self finishLassoAt: evt position ]
		ifFalse: [ dragMoved ifFalse: [ self clearSelection ] ].
	dragMode := nil
]

{ #category : 'navigation' }
AgentCanvas >> handleWheel: evt [
	evt consume.
	evt isScrollUp ifTrue: [ self zoomAt: evt position by: 1.1 ].
	evt isScrollDown ifTrue: [ self zoomAt: evt position by: 1 / 1.1 ]
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
	lassoElement position: aPoint.
	lassoElement extent: 1 @ 1.
	space ifNotNil: [ space root addChild: lassoElement ]
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
	lassoElement ifNotNil: [ lassoElement removeFromParent. lassoElement := nil ].
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
	(space isNil or: [ self isHeadlessSession ])
		ifTrue: [ content addChild: aWidget ]
		ifFalse: [ space enqueueTask: (BlTaskAction new action: [ content addChild: aWidget ]) ]
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
	self toolWidgets
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
