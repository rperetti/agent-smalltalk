"Load AgentSmalltalk's pinned production UI runtime, then save the image.

The explicit order is part of the production closure: Album needs Bloc's focus
runtime, while its two obsolete development hooks are satisfied by the local
compatibility package rather than the upstream Scripter tool. Toplo has cyclic
cross-package references, so its first load establishes classes and its clean
second compilation verifies that no undeclared association survives."
| root src phase loadProjectPackage toploPackages toploSource bootstrapUndeclaredCount |
root := FileLocator image asFileReference parent parent.
src := root / 'src'.
phase := 'dependency loading'.
toploPackages := #(
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
	'Toplo-Imported-Icons-MaterialDesign').

loadProjectPackage := [ :pkgName |
	| reader |
	reader := TonelReader on: src fileName: pkgName.
	reader loadDefinitions.
	MCPackageLoader updatePackage: (MCPackage named: pkgName) withSnapshot: reader snapshot ].

[
	Stdio stdout nextPutAll: 'AS_LOAD_PHASE dependency loading'; lf.
	Stdio stdout nextPutAll: 'AS_WARNING ASW-ALBUM-LEGACY-HOOKS'; lf.

Metacello new
	baseline: 'Alexandrie';
	repository: 'github://pharo-graphics/Alexandrie:4083bf84343b878521ebb4a26b5aa76cf28fa490/src';
	onConflictUseLoaded;
	load: 'production'.

Metacello new
	baseline: 'XMLParser';
	repository: 'github://pharo-contributions/XML-XMLParser:26a888381174c154b02e908f27d9d5eead3d04ec/src';
	onConflictUseLoaded;
	load: 'Core'.

Metacello new
	baseline: 'Bloc';
	repository: 'github://pharo-graphics/Bloc:041defd538e3e1caf17060eb0f44062c5c4c1a8f/src';
	onConflictUseLoaded;
	load: #(
		'Bloc-Animation'
		'Bloc-CommandApplier'
		'Bloc-FocusFinder'
		'Bloc-Overlay'
		'Bloc-SVG'
		'Bloc-Alexandrie'
		'BlocHost-Morphic'
		'BlocHost-OSWindow-SDL2').

loadProjectPackage value: 'AgentSmalltalk-UICompatibility'.

Metacello new
	baseline: 'Album';
	repository: 'github://pharo-graphics/Album:a20f74b190c41fabb2b2b27bbdaa0eb41c261d33/src';
	onConflictUseLoaded;
	load: 'Album'.

[ Metacello new
	baseline: 'Toplo';
	repository: 'github://pharo-graphics/Toplo:685e2497e6fff39682c4e66eebb7d33443c3f341/src';
	onConflictUseLoaded;
	load: toploPackages ] on: NewUndeclaredWarning do: [ :warning |
	bootstrapUndeclaredCount ifNil: [
		Stdio stdout nextPutAll: 'AS_WARNING ASW-TOPLO-CYCLIC-BOOTSTRAP'; lf ].
	bootstrapUndeclaredCount := (bootstrapUndeclaredCount ifNil: [ 0 ]) + 1.
	warning resume ].

phase := 'dependency recompilation'.
Stdio stdout nextPutAll: 'AS_LOAD_PHASE dependency recompilation'; lf.
toploSource := root / 'pharo' / 'pharo-local' / 'iceberg' / 'pharo-graphics' / 'Toplo' / 'src'.
[ toploPackages do: [ :pkgName |
		| reader |
		reader := TonelReader on: toploSource fileName: pkgName.
		reader loadDefinitions.
	MCPackageLoader updatePackage: (MCPackage named: pkgName) withSnapshot: reader snapshot ] ]
	on: NewUndeclaredWarning
	do: [ :warning | Error signal: 'Toplo dependency recompilation left an undeclared association: ', warning printString ].
bootstrapUndeclaredCount = 76 ifFalse: [
	Error signal: 'Toplo bootstrap reference count changed: ', bootstrapUndeclaredCount asString ].
Stdio stdout nextPutAll: 'AS_LOAD_TOPLO_CYCLIC_REFERENCES ', bootstrapUndeclaredCount asString; lf.

phase := 'project-package loading'.
Stdio stdout nextPutAll: 'AS_LOAD_PHASE project-package loading'; lf.
"The runtime has already been selected explicitly above. Load our Tonel
packages directly so Metacello does not re-plan the upstream projects with
their broad default declarations. AgentUpdater uses this same package order."
#('AgentSmalltalk-Core' 'AgentSmalltalk-UI' 'AgentSmalltalk-Tests' 'AgentSmalltalk-UITests' 'BaselineOfAgentSmalltalk')
	do: loadProjectPackage.
Stdio stdout nextPutAll: 'AS_LOAD_COMPLETE production closure'; lf.
Smalltalk snapshot: true andQuit: true
] on: Error do: [ :error |
	Stdio stderr nextPutAll: 'AS_LOAD_FAILED ', phase, ': ', error printString; lf.
	error pass ]
