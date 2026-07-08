"
I am the floating prompt bar. Summoned with Cmd/Ctrl+Return on the canvas,
I collect a request in a ToAlbum (multi-line, wrapping text editor: cursor,
selection, clipboard), run the AgentGateway in a background process, and show
its status line ('thinking... / evaluating... / working...') while the loop
runs. Enter/Esc are attached as event filters so they win over the editor —
Enter submits instead of inserting a newline.
"
Class {
	#name : 'AgentSpotlight',
	#superclass : 'BlElement',
	#instVars : [
		'canvas',
		'inputField',
		'statusLabel',
		'running',
		'runProcess'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'instance creation' }
AgentSpotlight class >> openOn: aCanvas [
	| bar existing |
	existing := aCanvas space root children asArray
		detect: [ :c | c isKindOf: self ] ifNone: [ nil ].
	existing ifNotNil: [ existing focusInput. ^ existing ].
	bar := self new.
	bar canvas: aCanvas.
	aCanvas space root addChild: bar.
	bar position: ((aCanvas space extent x - 620) / 2) @ 120.
	bar focusInput.
	^ bar
]

{ #category : 'initialization' }
AgentSpotlight >> initialize [
	super initialize.
	self background: (Color white alpha: 0.97).
	self border: (BlBorder paint: (Color gray alpha: 0.5) width: 1).
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 12).
	self layout: BlLinearLayout vertical.
	self padding: (BlInsets all: 14).
	self constraintsDo: [ :c |
		c horizontal exact: 620.
		c vertical fitContent ].
	inputField := ToAlbum new.
	inputField placeholderText: 'ask the agent...'.
	inputField constraintsDo: [ :c |
		c horizontal exact: 590.
		c vertical fitContent.
		c minHeight: 34 ].
	statusLabel := ToLabel new text: 'Return to run, Esc to close'.
	running := false.
	statusLabel beMultiLine.
	statusLabel margin: (BlInsets top: 8).
	statusLabel constraintsDo: [ :c | c horizontal exact: 590 ].
	self addChild: inputField.
	self addChild: statusLabel.
	inputField addEventFilterOn: BlKeyDownEvent do: [ :evt |
		evt key = KeyboardKey enter ifTrue: [ evt consume. self submit ].
		evt key = KeyboardKey escape ifTrue: [
			evt consume.
			self isRunning
				ifTrue: [ self cancel ]
				ifFalse: [ self close ] ] ]
]

{ #category : 'accessing' }
AgentSpotlight >> canvas: aCanvas [
	canvas := aCanvas
]

{ #category : 'actions' }
AgentSpotlight >> focusInput [
	inputField requestFocus
]

{ #category : 'private' }
AgentSpotlight >> showStatusNow: aString [
	statusLabel text: (self isRunning
		ifTrue: [ aString , ' — Esc cancels' ]
		ifFalse: [ aString ])
]

{ #category : 'private' }
AgentSpotlight >> showStatus: aString [
	"Safe to call from a non-UI process: defer the update onto the space pulse."
	self enqueueTask: (BlTaskAction new action: [
		self isRunning ifTrue: [ self showStatusNow: aString ] ])
]

{ #category : 'actions' }
AgentSpotlight >> submit [
	| request gateway |
	self isRunning ifTrue: [ ^ self ].
	request := inputField text asString trimBoth.
	request isEmpty ifTrue: [ ^ self ].
	running := true.
	self showStatusNow: 'thinking...'.
	gateway := AgentGateway new.
	gateway statusBlock: [ :msg | self showStatus: msg ].
	runProcess := [ [ gateway run: request.
		self enqueueTask: (BlTaskAction new action: [ self completeSuccess ]) ]
		on: Error
		do: [ :e |
			self enqueueTask: (BlTaskAction new action: [
				self completeFailure: e messageText ]) ] ]
		forkNamed: 'agent-spotlight-run'
]

{ #category : 'testing' }
AgentSpotlight >> isRunning [
	^ running == true
]

{ #category : 'actions' }
AgentSpotlight >> cancel [
	| process |
	self isRunning ifFalse: [ ^ self ].
	process := runProcess.
	runProcess := nil.
	running := false.
	process ifNotNil: [
		[ process terminate ] on: Error do: [ :ignored |  ] ].
	self showStatusNow: 'cancelled — edit and Return to retry'
]

{ #category : 'private' }
AgentSpotlight >> completeSuccess [
	self isRunning ifFalse: [ ^ self ].
	running := false.
	runProcess := nil.
	self close
]

{ #category : 'private' }
AgentSpotlight >> completeFailure: messageText [
	self isRunning ifFalse: [ ^ self ].
	running := false.
	runProcess := nil.
	self showStatusNow: 'FAILED: ' , messageText
]

{ #category : 'actions' }
AgentSpotlight >> close [
	self removeFromParent
]
