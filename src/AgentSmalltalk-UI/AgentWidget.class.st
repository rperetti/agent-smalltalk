"
I am the base class every LLM-generated widget subclasses. I provide the contract:
a padded, draggable card on the canvas; subclasses build their UI in #initialize
and override #describe with a one-line self-description used as LLM context.
Right-click opens a browser on the generated source ('knowledge = code', visibly).
"
Class {
	#name : 'AgentWidget',
	#superclass : 'BlElement',
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

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
	self border: (BlBorder paint: (Color gray alpha: 0.4) width: 1).
	self geometry: (BlRoundedRectangleGeometry cornerRadius: 10).
	self layout: BlLinearLayout vertical.
	self padding: (BlInsets all: 12).
	self addEventHandler: BlPullHandler new.
	self addEventHandlerOn: BlClickEvent do: [ :evt |
		evt button = BlMouseButton secondary ifTrue: [
			evt consume.
			self browseSource ] ]
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
