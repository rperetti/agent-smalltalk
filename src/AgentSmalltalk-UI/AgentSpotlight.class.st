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
		'statusLabel'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'instance creation' }
AgentSpotlight class >> openOn: aCanvas [
	| bar |
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
	statusLabel margin: (BlInsets top: 8).
	self addChild: inputField.
	self addChild: statusLabel.
	inputField addEventFilterOn: BlKeyDownEvent do: [ :evt |
		evt key = KeyboardKey enter ifTrue: [ evt consume. self submit ].
		evt key = KeyboardKey escape ifTrue: [ evt consume. self close ] ]
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
	statusLabel text: aString
]

{ #category : 'private' }
AgentSpotlight >> showStatus: aString [
	"Safe to call from a non-UI process: defer the update onto the space pulse."
	self enqueueTask: (BlTaskAction new action: [ self showStatusNow: aString ])
]

{ #category : 'actions' }
AgentSpotlight >> submit [
	| request gateway |
	request := inputField text asString trimBoth.
	request isEmpty ifTrue: [ ^ self ].
	gateway := AgentGateway new.
	gateway statusBlock: [ :msg | self showStatus: msg ].
	[ [ gateway run: request.
		self showStatus: 'done'.
		self closeSoon ]
		on: Error
		do: [ :e | self showStatus: 'FAILED: ' , e messageText ] ]
		forkNamed: 'agent-spotlight-run'
]

{ #category : 'actions' }
AgentSpotlight >> close [
	self removeFromParent
]

{ #category : 'actions' }
AgentSpotlight >> closeSoon [
	[ 1.5 seconds wait.
	self enqueueTask: (BlTaskAction new action: [ self close ]) ]
		forkNamed: 'agent-spotlight-close'
]
