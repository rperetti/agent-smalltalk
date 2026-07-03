Class {
	#name : 'BaselineOfAgentSmalltalk',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfAgentSmalltalk',
	#package : 'BaselineOfAgentSmalltalk'
}

{ #category : 'baselines' }
BaselineOfAgentSmalltalk >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			baseline: 'Bloc'
			with: [ spec repository: 'github://pharo-graphics/Bloc:master/src' ].
		spec
			baseline: 'Toplo'
			with: [ spec repository: 'github://pharo-graphics/Toplo:master/src' ].
		spec
			package: 'AgentSmalltalk-Core';
			package: 'AgentSmalltalk-UI' with: [ spec requires: #('AgentSmalltalk-Core' 'Bloc' 'Toplo') ];
			package: 'AgentSmalltalk-Tests' with: [ spec requires: #('AgentSmalltalk-Core') ].
		spec
			group: 'Core' with: #('AgentSmalltalk-Core' 'AgentSmalltalk-Tests');
			group: 'default' with: #('AgentSmalltalk-Core' 'AgentSmalltalk-UI' 'AgentSmalltalk-Tests') ]
]
