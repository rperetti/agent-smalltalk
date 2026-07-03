"
I am the floating prompt bar. Summoned with Cmd/Ctrl+Return on the canvas,
I collect a request, run the AgentGateway in a background process, and show
its status line ('thinking… / evaluating… / repairing…') while the loop runs.
Text input is handled manually (BlTextInputEvent + backspace) to avoid a
widget-set dependency.
"
Class {
	#name : 'AgentSpotlight',
	#superclass : 'BlElement',
	#instVars : [
		'canvas',
		'inputText',
		'inputLabel',
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
	bar requestFocus.
	^ bar
]

{ #category : 'initialization' }
AgentSpotlight >> initialize [
	super initialize.
	inputText := ''.
	self extent: 620 @ 92.
	self background: (Color white alpha: 0.97).
	self border: (BlBorder paint: (Color gray alpha: 0.5) width: 1).
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 12).
	self layout: BlLinearLayout vertical.
	self padding: (BlInsets all: 14).
	inputLabel := BlTextElement new.
	statusLabel := BlTextElement new.
	self refreshInput.
	self showStatusNow: 'type a request, Return to run, Esc to close'.
	self addChild: inputLabel.
	self addChild: statusLabel.
	self addEventHandlerOn: BlTextInputEvent do: [ :evt |
		inputText := inputText , evt text asString.
		self refreshInput ].
	self addEventHandlerOn: BlKeyDownEvent do: [ :evt |
		evt key = KeyboardKey backspace ifTrue: [
			inputText ifNotEmpty: [
				inputText := inputText allButLast.
				self refreshInput ] ].
		evt key = KeyboardKey escape ifTrue: [ self close ].
		evt key = KeyboardKey enter ifTrue: [ self submit ] ]
]

{ #category : 'accessing' }
AgentSpotlight >> canvas: aCanvas [
	canvas := aCanvas
]

{ #category : 'private' }
AgentSpotlight >> refreshInput [
	inputLabel text: ((inputText , '▏') asRopedText fontSize: 20)
]

{ #category : 'private' }
AgentSpotlight >> showStatusNow [
	^ self
]

{ #category : 'private' }
AgentSpotlight >> showStatusNow: aString [
	statusLabel text: ((aString asRopedText fontSize: 12) foreground: Color gray)
]

{ #category : 'private' }
AgentSpotlight >> showStatus: aString [
	"Safe to call from a non-UI process: defer the update onto the space pulse."
	self enqueueTask: (BlTaskAction new action: [ self showStatusNow: aString ])
]

{ #category : 'actions' }
AgentSpotlight >> submit [
	| request gateway |
	request := inputText trimBoth.
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
