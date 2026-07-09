"
I am the base class every LLM-generated widget subclasses. I provide the contract:
a padded, draggable card on the canvas; subclasses build their UI in #initialize
and override #describe with a one-line self-description used as LLM context.
Right-click opens a browser on the generated source ('knowledge = code', visibly).
"
Class {
	#name : 'AgentWidget',
	#superclass : 'BlElement',
	#instVars : [
		'resizeGrip',
		'resizeStart',
		'resizeStartExtent',
		'raiseWired',
		'deleteButton'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'class creation' }
AgentWidget class >> defineNamed: aSymbol slots: slotSymbols [
	"Blessed entry point for the LLM to create widget classes, insulating it
	from class-builder API drift. Re-running with more slots migrates
	existing instances (new slots start as nil)."
	^ self << aSymbol asSymbol
		slots: slotSymbols;
		package: 'AgentSmalltalk-Generated';
		install
]

{ #category : 'instance creation' }
AgentWidget class >> summonAt: aPoint [
	| widget |
	widget := self new.
	widget position: aPoint.
	AgentCanvas current addWidget: widget.
	^ widget
]

{ #category : 'initialization' }
AgentWidget >> initialize [
	super initialize.
	self extent: 240 @ 160.
	self background: Color white.
	self border: self defaultBorder.
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 10).
	self layout: BlLinearLayout vertical.
	self padding: (BlInsets all: 12).
	self addEventHandler: BlPullHandler new.
	self addEventHandlerOn: BlClickEvent do: [ :evt |
		evt button = BlMouseButton secondary ifTrue: [
			evt consume.
			self browseSource ] ].
	self ensureResizeGrip.
	self ensureRaisesOnClick.
	self ensureDeleteButton
]

{ #category : 'deleting' }
AgentWidget >> showsDeleteButton [
	"Every widget gets a floating delete x by default. Stickies override to
	false -- they already carry an x in their header row."
	^ true
]

{ #category : 'deleting' }
AgentWidget >> refreshDeleteButton [
	"Migration: drop any existing delete button and rebuild it with the
	current style (so widgets made before a style change get restyled)."
	deleteButton ifNotNil: [ deleteButton removeFromParent. deleteButton := nil ].
	self ensureDeleteButton
]

{ #category : 'deleting' }
AgentWidget >> ensureDeleteButton [
	"A small floating x in the top-right corner (ignoreByLayout, so it never
	disturbs the widget's own layout). Idempotent for the update migration."
	self showsDeleteButton ifFalse: [ ^ self ].
	deleteButton ifNotNil: [ ^ self ].
	"Same glyph style as the sticky delete x, for a consistent look."
	deleteButton := BlTextElement new text: ('x' asRopedText fontSize: 14).
	deleteButton constraintsDo: [ :c |
		c ignoreByLayout.
		c ignored horizontal alignRight.
		c ignored vertical alignTop ].
	deleteButton margin: (BlInsets top: 2 right: 6 bottom: 0 left: 0).
	deleteButton addEventHandlerOn: BlClickEvent do: [ :evt |
		evt consume.
		self removeFromParent ].
	self addChild: deleteButton
]

{ #category : 'z order' }
AgentWidget >> ensureRaisesOnClick [
	"Any press anywhere on the widget (including inside its editors) brings
	it to the front. Not consumed: dragging, clicking, editing all proceed.
	Idempotent for the update migration."
	raiseWired == true ifTrue: [ ^ self ].
	self addEventHandlerOn: BlMouseDownEvent do: [ :evt | self raise ].
	raiseWired := true
]

{ #category : 'z order' }
AgentWidget >> raise [
	"Must be a BlElevation object: Bloc's picking sorter sends #elevation
	to the stored value, so a raw integer breaks every mouse move."
	self elevation: (BlRelativeElevation elevation: AgentCanvas current nextTopElevation)
]

{ #category : 'z order' }
AgentWidget >> repairElevation [
	"Migration: heal widgets poisoned by the raw-integer raise bug."
	self elevation isNumber ifTrue: [
		self elevation: (BlRelativeElevation elevation: self elevation) ]
]

{ #category : 'resizing' }
AgentWidget >> ensureResizeGrip [
	"A small bottom-right grip; drag it to resize (min 120x80). Idempotent,
	so the update migration can call it on pre-grip widgets."
	resizeGrip ifNotNil: [ ^ self ].
	resizeGrip := BlElement new.
	resizeGrip extent: 12 @ 12.
	resizeGrip background: (Color gray alpha: 0.25).
	resizeGrip geometry: (BlRoundedRectangleGeometry cornerRadius: 3).
	resizeGrip constraintsDo: [ :c |
		c ignoreByLayout.
		c ignored horizontal alignRight.
		c ignored vertical alignBottom ].
	resizeGrip addEventHandlerOn: BlDragStartEvent do: [ :evt |
		evt consume.
		resizeStart := evt position.
		resizeStartExtent := self extent ].
	resizeGrip addEventHandlerOn: BlDragEvent do: [ :evt |
		evt consume.
		resizeStart ifNotNil: [
			self resizeTo: resizeStartExtent
				+ ((evt position - resizeStart) / AgentCanvas current zoom) ] ].
	resizeGrip addEventHandlerOn: BlDragEndEvent do: [ :evt |
		evt consume.
		resizeStart := nil ].
	self addChild: resizeGrip
]

{ #category : 'resizing' }
AgentWidget >> resizeTo: aPoint [
	self extent: (aPoint max: 120 @ 80)
]

{ #category : 'actions' }
AgentWidget >> removeFromParent [
	"Deletions are undoable: the canvas remembers removed widgets (Cmd+Z).
	Subscriptions die with the widget so deleted widgets don't leak handlers."
	(AgentCanvas current containsWidget: self)
		ifTrue: [
			AgentCanvas current recordDeletion: self.
			self removedFromCanvas ].
	AgentCanvas current announcer unsubscribe: self.
	super removeFromParent
]

{ #category : 'deleting' }
AgentWidget >> removedFromCanvas [
	"Lifecycle hook for widgets whose canvas presence owns durable behavior."
]

{ #category : 'deleting' }
AgentWidget >> restoredToCanvas [
	"Lifecycle hook paired with #removedFromCanvas. AgentCanvas invokes it
	after deletion undo restores the same live widget."
]

{ #category : 'reactions' }
AgentWidget >> flashUpdated [
	"Blink an accent border so reactions are VISIBLE -- a widget that
	updates itself imperceptibly reads as broken. UI mutations are always
	enqueued on the live space; the background process only owns the delay."
	self runOnUiThread: [
		self border: (BlBorder paint: (Color fromHexString: '4A90D9') width: 2) ].
	[ (Delay forSeconds: 1) wait.
	self runOnUiThread: [
		(AgentCanvas current selectedWidgets includes: self)
			ifTrue: [ self highlightSelected ]
			ifFalse: [ self border: self defaultBorder ] ] ]
		forkNamed: 'agent-flash'
]

{ #category : 'private' }
AgentWidget >> runOnUiThread: aBlock [
	| canvas |
	canvas := AgentCanvas current.
	(canvas isOpen and: [ canvas isHeadlessSession not ])
		ifTrue: [
			canvas space enqueueTask: (BlTaskAction new action: aBlock).
			canvas space requestNextPulse ]
		ifFalse: [ aBlock value ]
]

{ #category : 'private' }
AgentWidget >> runOnUiThreadSafely: aBlock [
	"Run a background result on the UI thread and catch errors where the
	queued block actually executes. A handler around the caller's fork is
	too early in a live GUI: enqueueing returns before the UI block runs."
	self runOnUiThread: [
		[ aBlock value ]
			on: Error
			do: [ :error |
				[ AgentSystemMessage
					post: 'Widget update failed in ' , self class name , ': '
						, error messageText
					key: ('widgetUpdateFailure-' , self class name) asSymbol ]
					on: Error
					do: [ :ignored |  ] ] ]
]

{ #category : 'text' }
AgentWidget >> setText: aString on: aTextElement fontSize: aNumber [
	"Blessed styled-text update. Keeping keyword precedence inside this
	hand-written method prevents generated code from accidentally sending
	the nonexistent #text:fontSize: selector."
	aTextElement text: (aString asString asRopedText fontSize: aNumber)
]

{ #category : 'reactions' }
AgentWidget >> announceChanged [
	"Convention: state-mutating methods end with this, so derived widgets
	(totals, charts) can react instead of needing Refresh buttons."
	AgentCanvas current announcer announce:
		(AgentWidgetChanged new widget: self; yourself)
]

{ #category : 'agent context' }
AgentWidget >> describe [
	"One-line self-description used as LLM context. Subclasses should override."
	^ 'a widget with no description'
]

{ #category : 'actions' }
AgentWidget >> browseSource [
	self class browse
]

{ #category : 'selection' }
AgentWidget >> defaultBorder [
	^ BlBorder paint: (Color gray alpha: 0.4) width: 1
]

{ #category : 'selection' }
AgentWidget >> highlightSelected [
	self border: (BlBorder paint: (Color fromHexString: '4A90D9') width: 3)
]

{ #category : 'selection' }
AgentWidget >> unhighlight [
	self border: self defaultBorder
]
