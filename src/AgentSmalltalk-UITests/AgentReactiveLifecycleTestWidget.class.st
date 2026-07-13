"
Reactive probe for the canvas undo lifecycle. It intentionally subscribes only
from #installReactions, as generated reactive widgets must now do.
"
Class {
	#name : 'AgentReactiveLifecycleTestWidget',
	#superclass : 'AgentWidget',
	#instVars : [
		'factReactionCount',
		'widgetReactionCount',
		'initialCity'
	],
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'initialization' }
AgentReactiveLifecycleTestWidget >> initialize [
	super initialize.
	initialCity := AgentKnowledge at: #city.
	factReactionCount := 0.
	widgetReactionCount := 0
]

{ #category : 'reactions' }
AgentReactiveLifecycleTestWidget >> installReactions [
	AgentCanvas current announcer
		when: AgentFactChanged
		do: [ :event | factReactionCount := factReactionCount + 1 ]
		for: self.
	AgentCanvas current announcer
		when: AgentWidgetChanged
		do: [ :event | widgetReactionCount := widgetReactionCount + 1 ]
		for: self
]

{ #category : 'accessing' }
AgentReactiveLifecycleTestWidget >> factReactionCount [
	^ factReactionCount
]

{ #category : 'accessing' }
AgentReactiveLifecycleTestWidget >> initialCity [
	^ initialCity
]

{ #category : 'accessing' }
AgentReactiveLifecycleTestWidget >> widgetReactionCount [
	^ widgetReactionCount
]
