"
Announced on the canvas announcer when a widget's state changes (the widget
convention: state-mutating methods end with 'self announceChanged'). Derived
widgets subscribe and recompute -- no Refresh buttons.
"
Class {
	#name : 'AgentWidgetChanged',
	#superclass : 'Announcement',
	#instVars : [
		'widget'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentWidgetChanged >> widget [
	^ widget
]

{ #category : 'accessing' }
AgentWidgetChanged >> widget: anAgentWidget [
	widget := anAgentWidget
]
