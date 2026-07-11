"Load AgentSmalltalk's pinned production UI runtime, then save the image.

Load upstream projects before our baseline so their own broad dependency
declarations cannot replace the exact runtime closure below."
| root src |
root := FileLocator image asFileReference parent parent.
src := root / 'src'.

Metacello new
	baseline: 'Alexandrie';
	repository: 'github://pharo-graphics/Alexandrie:d3185a6f5e4041a2054025c24a5120fd0108b164/src';
	onConflictUseLoaded;
	load: 'production'.

Metacello new
	baseline: 'XMLParser';
	repository: 'github://pharo-contributions/XML-XMLParser:26a888381174c154b02e908f27d9d5eead3d04ec/src';
	onConflictUseLoaded;
	load: 'Core'.

Metacello new
	baseline: 'Bloc';
	repository: 'github://pharo-graphics/Bloc:a863816b9e526826d66286d871fef7042b03f546/src';
	onConflictUseLoaded;
	load: #(
		'Bloc-Animation'
		'Bloc-CommandApplier'
		'Bloc-Overlay'
		'Bloc-SVG'
		'Bloc-Alexandrie'
		'BlocHost-OSWindow-SDL2').

Metacello new
	baseline: 'Album';
	repository: 'github://pharo-graphics/Album:a20f74b190c41fabb2b2b27bbdaa0eb41c261d33/src';
	onConflictUseLoaded;
	load: 'Album'.

Metacello new
	baseline: 'Toplo';
	repository: 'github://pharo-graphics/Toplo:685e2497e6fff39682c4e66eebb7d33443c3f341/src';
	onConflictUseLoaded;
	load: #(
		'Toplo-Theme-Bee'
		'Toplo-Widget-Album'
		'Toplo-Widget-Button'
		'Toplo-Widget-ProgressBar'
		'Toplo-Widget-Empty'
		'Toplo-Widget-Float'
		'Toplo-Widget-Menu'
		'Toplo-Imported-Icons-MaterialDesign').

"The runtime has already been selected explicitly above. Load our Tonel
packages directly so Metacello does not re-plan the upstream projects with
their broad default declarations. This is the same loader used by updates."
#('AgentSmalltalk-Core' 'AgentSmalltalk-UI' 'AgentSmalltalk-Tests' 'AgentSmalltalk-UITests' 'BaselineOfAgentSmalltalk')
	do: [ :pkgName |
		| reader |
		reader := TonelReader on: src fileName: pkgName.
		reader loadDefinitions.
		MCPackageLoader updatePackage: (MCPackage named: pkgName) withSnapshot: reader snapshot ].
Smalltalk snapshot: true andQuit: true
