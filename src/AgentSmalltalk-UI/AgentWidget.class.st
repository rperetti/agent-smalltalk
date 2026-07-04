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
		'raiseWired'
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
	self ensureRaisesOnClick
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
	self elevation: AgentCanvas current nextTopElevation
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
	"Deletions are undoable: the canvas remembers removed widgets (Cmd+Z)."
	(AgentCanvas current containsWidget: self)
		ifTrue: [ AgentCanvas current recordDeletion: self ].
	super removeFromParent
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
