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

{ #category : 'class creation' }
AgentWidget class >> compile: source [
	"Framework policy, not a user-facing convention: a canvas-announcer
	subscription in #initialize cannot survive deletion undo. Reject it before
	it enters the image so the code engine receives a precise repair instruction."
	self assertReactionLifecycleFor: source.
	self assertPortableTextLiteralsFor: source.
	^ super compile: source
]

{ #category : 'class creation' }
AgentWidget class >> assertPortableTextLiteralsFor: source [
	"Generated text must render in the default font on every supported host.
	Ordinary non-ASCII language text remains valid; reject only code points in
	the emoji, dingbat and pictograph ranges."
	(source anySatisfy: [ :character |
		self isPictographicCodePoint: character asInteger ]) ifTrue: [
		self error: 'Generated widget text must not contain emoji or Unicode pictographs; their glyphs are not portable across UI hosts and abort the canvas render. Use a plain-text label.' ]
]

{ #category : 'class creation' }
AgentWidget class >> isPictographicCodePoint: codePoint [
	"Portable generated labels may still contain ordinary Unicode text,
	including accents, currency and the degree sign. These ranges cover emoji,
	dingbats and their presentation/keycap modifiers rather than all non-ASCII."
	(codePoint between: 16r1F000 and: 16r1FAFF) ifTrue: [ ^ true ].
	(codePoint between: 16r2600 and: 16r27BF) ifTrue: [ ^ true ].
	(codePoint between: 16r2300 and: 16r23FF) ifTrue: [ ^ true ].
	(codePoint between: 16r2B00 and: 16r2BFF) ifTrue: [ ^ true ].
	^ codePoint = 16r20E3 or: [ codePoint = 16rFE0F ]
]

{ #category : 'class creation' }
AgentWidget class >> assertReactionLifecycleFor: source [
	"Catch the concrete anti-pattern without constraining ordinary widget setup
	or subscriptions to unrelated models. Generated code compiles methods one at
	a time, so this error is returned to the model before it creates an instance."
	| trimmed |
	trimmed := source trimBoth.
	((trimmed beginsWith: 'initialize')
		and: [ (trimmed includesSubstring: 'AgentCanvas')
			and: [ trimmed includesSubstring: 'when:' ] ]) ifTrue: [
		self error: 'Canvas-announcer subscriptions belong in #installReactions, not #initialize. Compile that hook instead; the canvas reconnects it after undo.' ]
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
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 12).
	self layout: BlLinearLayout vertical.
	self padding: (BlInsets all: 12).
	self addEventHandler: BlPullHandler new.
	self addEventHandlerOn: BlClickEvent do: [ :evt |
		evt button = BlMouseButton secondary ifTrue: [
			evt consume.
			self browseSource ] ].
	self ensureResizeGrip.
	self ensureRaisesOnClick.
	self ensureDeleteButton.
	"Redesign: every card floats off the paper with a soft shadow. Categorised
	cards additionally call #applyCardChrome for the white body + chip header."
	self applyDropShadow
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

{ #category : 'migration' }
AgentWidget >> removeUnrenderableIconElements [
	"Migration: the reverted portable-icon experiment left some widgets holding a
	Toplo Material ToImage whose glyph is a BlSvgPath. BlSvgPath has no Alexandrie
	draw method (subclassResponsibility), so painting such a widget aborts the
	whole canvas render. Strip the icon element -- the widget keeps its text and
	renders again. Matched by geometry class name so it needs neither class loaded."
	| doomed |
	doomed := OrderedCollection new.
	self allChildrenBreadthFirstDo: [ :each |
		each geometry class name = #BlSvgPath ifTrue: [
			"Climb to the owning ToImage (the svg sits a couple of wrappers deep)
			and drop the whole icon, not just the path element."
			| top |
			top := each.
			[ top parent notNil and: [ top parent ~~ self
				and: [ top class name ~= #ToImage ] ] ]
				whileTrue: [ top := top parent ].
			doomed add: top ] ].
	doomed do: [ :each | each parent ifNotNil: [ each removeFromParent ] ]
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
	self uninstallReactions.
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
	self reconnectReactions
]

{ #category : 'reactions' }
AgentWidget >> addedToCanvas [
	"Called after the canvas attaches a new widget. Subscription setup belongs
	here rather than in #initialize, so the same hook also works after undo."
	self reconnectReactions
]

{ #category : 'reactions' }
AgentWidget >> installReactions [
	"Override in reactive widgets. Put every canvas-announcer subscription here,
	using #when:do:for: self; never subscribe directly from #initialize."
]

{ #category : 'reactions' }
AgentWidget >> uninstallReactions [
	"Override only to release other reaction resources; send super so the
	canvas announcer no longer retains this removed widget."
	AgentCanvas current announcer unsubscribe: self
]

{ #category : 'reactions' }
AgentWidget >> reconnectReactions [
	"Idempotently install exactly the current widget's reactions. The canvas
	invokes this after initial attachment and undo; generated-code migrations
	may send it to existing live instances after compiling #installReactions."
	(AgentCanvas current containsWidget: self) ifFalse: [ ^ self ].
	self uninstallReactions.
	self installReactions
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
	canvas isInteractive
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

{ #category : 'automations' }
AgentWidget >> automationActionDescription [
	"Short status text for the default scheduled automation hook."
	^ self class name , ' refreshed'
]

{ #category : 'automations' }
AgentWidget >> runAutomatedAction [
	"Default zero-argument automation contract for widgets. Automations should
	delegate to this hook instead of copying a widget's fetch/parse/apply
	behavior. Generated widgets are automatable out of the box when they
	provide the common #refresh method; specialized widgets may override this
	method to do something more precise and return AgentAutomationResult."
	| result |
	(self respondsTo: #refresh) ifFalse: [
		self error: self class name
			, ' has no automated action; add #refresh or override #runAutomatedAction before scheduling it' ].
	result := self perform: #refresh.
	(result isKindOf: AgentAutomationResult) ifTrue: [ ^ result ].
	^ AgentAutomationResult unchanged: self automationActionDescription
]

{ #category : 'agent context' }
AgentWidget >> describe [
	"One-line self-description used as LLM context. Subclasses should override."
	^ 'a widget with no description'
]

{ #category : 'knowledge catalog' }
AgentWidget >> contributesToKnowledgeCatalog [
	^ true
]

{ #category : 'knowledge catalog' }
AgentWidget >> knowledgeProjectionWithHandle: aHandle selected: isSelected [
	| description |
	description := self describe.
	^ AgentKnowledgeProjection
		handle: aHandle
		kind: #widget
		key: nil
		label: self class name
		summary: description
		content: description
		selected: isSelected
		source: self
]

{ #category : 'actions' }
AgentWidget >> browseSource [
	self class browse
]

{ #category : 'selection' }
AgentWidget >> defaultBorder [
	"The redesign hairline: every card (plain widgets included) reads as one
	family -- the soft shadow lifts it, not a heavy outline."
	^ self chipCardBorder
]

{ #category : 'selection' }
AgentWidget >> highlightSelected [
	self border: (BlBorder paint: (Color fromHexString: '4A90D9') width: 3)
]

{ #category : 'selection' }
AgentWidget >> unhighlight [
	self border: self defaultBorder
]

{ #category : 'redesign chrome' }
AgentWidget >> chipAccent [
	"The header-chip background -- the category colour. Overridden per card."
	^ Color fromHexString: 'E8E8E5'
]

{ #category : 'redesign chrome' }
AgentWidget >> chipIconColor [
	"The small rounded square in the chip, a deeper shade of the accent."
	^ Color fromHexString: 'B9B9B3'
]

{ #category : 'redesign chrome' }
AgentWidget >> chipCategory [
	"The uppercased word shown in the chip (FACT, NOTE, SERVICE...)."
	^ 'WIDGET'
]

{ #category : 'redesign chrome' }
AgentWidget >> chipCardBorder [
	"A hairline; the drop shadow does the lifting, not a heavy border."
	^ BlBorder paint: (Color black alpha: 0.06) width: 1
]

{ #category : 'redesign chrome' }
AgentWidget >> applyDropShadow [
	"Soft drop shadow so the card floats off the paper. Guarded: the exact Bloc
	shadow-effect class/selector varies across pinned revisions, and a mismatch
	must never stop a card from rendering -- it just loses the shadow."
	| shadowClass |
	shadowClass := Smalltalk globals at: #BlGaussianShadowEffect ifAbsent: [ nil ].
	shadowClass ifNil: [ ^ self ].
	[ self effect: (shadowClass
		color: (Color black alpha: 0.12)
		width: 14
		offset: 0 @ 5) ]
		on: Error do: [ :e |  ]
]

{ #category : 'redesign chrome' }
AgentWidget >> applyCardChrome [
	"The redesigned card shell: white body, rounded, clipped so an edge-to-edge
	chip header's top corners follow the card, hairline border, soft shadow.
	Card padding is 0 -- the header is edge-to-edge and each body owns its own."
	self background: Color white.
	self border: self chipCardBorder.
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 12).
	self padding: (BlInsets all: 0).
	self clipChildren: true.
	self applyDropShadow.
	self bringGripToFront
]

{ #category : 'redesign chrome' }
AgentWidget >> bringGripToFront [
	"Re-add the resize grip as the last child so it paints on top of a
	full-bleed body and still receives the resize drag. Cards with 0 padding
	(the chip cards) have a body element that would otherwise cover the corner
	grip and swallow the gesture."
	resizeGrip ifNotNil: [
		resizeGrip removeFromParent.
		self addChild: resizeGrip ]
]

{ #category : 'redesign chrome' }
AgentWidget >> chipHeaderElement [
	"An edge-to-edge coloured category chip: icon + uppercased label + a spacer
	that pushes any trailing elements (status badge, delete x) to the right.
	Callers append those and add the returned header to the card."
	| header icon label spacer |
	header := BlElement new.
	header layout: BlLinearLayout horizontal.
	header background: self chipAccent.
	header padding: (BlInsets top: 7 right: 10 bottom: 7 left: 10).
	header constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	icon := BlElement new.
	icon extent: 14 @ 14.
	icon background: self chipIconColor.
	icon geometry: (BlRoundedRectangleGeometry cornerRadius: 4).
	icon margin: (BlInsets top: 0 right: 8 bottom: 0 left: 0).
	label := BlTextElement new
		text: (self chipCategory asUppercase asRopedText fontSize: 11; bold).
	label opacity: 0.75.
	spacer := BlElement new.
	spacer constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical exact: 1 ].
	header addChild: icon.
	header addChild: label.
	header addChild: spacer.
	^ header
]

{ #category : 'redesign chrome' }
AgentWidget >> chipDeleteButton [
	"The delete x for the right of a chip header, wired to remove the card."
	| deleteX |
	deleteX := BlTextElement new text: ('x' asRopedText fontSize: 14).
	deleteX opacity: 0.5.
	deleteX addEventHandlerOn: BlClickEvent do: [ :evt |
		evt consume.
		self removeFromParent ].
	^ deleteX
]

{ #category : 'redesign chrome' }
AgentWidget >> chipBadge: aString [
	"A small rounded status pill for the right of a chip (e.g. 'succeeded')."
	| badge |
	badge := ToLabel new text: aString asString.
	badge background: (Color white alpha: 0.5).
	badge geometry: (BlRoundedRectangleGeometry cornerRadius: 8).
	badge padding: (BlInsets top: 1 right: 7 bottom: 1 left: 7).
	badge margin: (BlInsets top: 0 right: 8 bottom: 0 left: 0).
	badge constraintsDo: [ :c | c vertical fitContent ].
	^ badge
]
