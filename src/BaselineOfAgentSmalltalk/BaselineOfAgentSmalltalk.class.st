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
		"Declare the production closure at exact revisions before Bloc/Toplo.
		Their upstream baselines follow moving branches and their default groups
		include tests, examples, and development tools.  These root declarations
		make fresh AgentSmalltalk images reproducible without loading that unused
		surface.  The listed Toplo packages are also the public widget vocabulary
		advertised by prompts/system.md."
		spec
			baseline: 'Alexandrie'
			with: [
				spec
					repository: 'github://pharo-graphics/Alexandrie:4083bf84343b878521ebb4a26b5aa76cf28fa490/src';
					loads: #('production') ].
		spec
			baseline: 'XMLParser'
			with: [
				spec
					repository: 'github://pharo-contributions/XML-XMLParser:26a888381174c154b02e908f27d9d5eead3d04ec/src';
					loads: #('Core') ].
		spec
			baseline: 'OrderPreservingDictionary'
			with: [
				spec
					repository: 'github://pharo-contributions/OrderPreservingDictionary:7b3ab363379e35a3e0e0183b6c2d193a675f898f/src';
					loads: #('Core') ].
		spec
			baseline: 'Album'
			with: [
				spec
					repository: 'github://pharo-graphics/Album:a20f74b190c41fabb2b2b27bbdaa0eb41c261d33/src';
					loads: #('Album') ].
		spec
			baseline: 'Bloc'
			with: [
				spec
					repository: 'github://pharo-graphics/Bloc:041defd538e3e1caf17060eb0f44062c5c4c1a8f/src';
					loads: #(
						'Bloc-Animation'
						'Bloc-CommandApplier'
						'Bloc-FocusFinder'
						'Bloc-Overlay'
						'Bloc-SVG'
						'Bloc-Alexandrie'
						'BlocHost-Morphic'
						'BlocHost-OSWindow-SDL2') ].
		spec
			baseline: 'Toplo'
			with: [
				spec
					repository: 'github://pharo-graphics/Toplo:685e2497e6fff39682c4e66eebb7d33443c3f341/src';
					loads: #(
						'Toplo'
						'Toplo-Theme'
						'Toplo-Theme-Bee'
						'Toplo-Widget-Album'
						'Toplo-Widget-Button'
						'Toplo-Widget-Circular'
						'Toplo-Widget-InnerWindow'
						'Toplo-Widget-Image'
						'Toplo-Widget-List'
						'Toplo-Widget-Pane'
						'Toplo-Widget-ProgressBar'
						'Toplo-Widget-Empty'
						'Toplo-Widget-Float'
						'Toplo-Widget-Menu'
						'Toplo-Imported-Icons-MaterialDesign') ].
		spec
			package: 'AgentSmalltalk-Core';
			package: 'AgentSmalltalk-UICompatibility' with: [ spec requires: #('Bloc') ];
			package: 'AgentSmalltalk-UI' with: [ spec requires: #('AgentSmalltalk-Core' 'AgentSmalltalk-UICompatibility' 'Bloc' 'Toplo') ];
			package: 'AgentSmalltalk-Tests' with: [ spec requires: #('AgentSmalltalk-Core') ];
			package: 'AgentSmalltalk-UITests' with: [ spec requires: #('AgentSmalltalk-UI') ].
		spec
			group: 'Core' with: #('AgentSmalltalk-Core' 'AgentSmalltalk-Tests');
			group: 'default' with: #('AgentSmalltalk-Core' 'AgentSmalltalk-UICompatibility' 'AgentSmalltalk-UI' 'AgentSmalltalk-Tests' 'AgentSmalltalk-UITests') ]
]
