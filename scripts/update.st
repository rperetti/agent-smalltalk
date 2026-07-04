"Reload the AgentSmalltalk packages from src/ into the LIVING image and save.
Goes through TonelReader + Monticello directly (not Metacello, whose registry
no-ops when the baseline version is unchanged). MC applies a diff: changed
tooling methods recompile in place, removed ones disappear. Generated widget
classes (AgentSmalltalk-Generated), live instances, facts, and all other
world state are untouched. Dependencies (Bloc/Toplo) are NOT reloaded —
run ./build.sh for dependency changes."
| src |
src := FileLocator image asFileReference parent parent / 'src'.
#('AgentSmalltalk-Core' 'AgentSmalltalk-UI' 'AgentSmalltalk-Tests' 'AgentSmalltalk-UITests' 'BaselineOfAgentSmalltalk')
	do: [ :pkgName |
		| reader |
		Stdio stdout nextPutAll: 'reloading ' , pkgName; lf.
		reader := TonelReader on: src fileName: pkgName.
		reader loadDefinitions.
		"Diff against the in-image package so removed definitions unload too."
		MCPackageLoader updatePackage: (MCPackage named: pkgName) withSnapshot: reader snapshot ].
"Migration: deliver setup steps to already-live objects (an open canvas
never re-runs #open, so new wiring must be applied explicitly)."
(Smalltalk globals at: #AgentCanvas ifAbsent: [ nil ]) ifNotNil: [ :cls |
	cls isOpen ifTrue: [
		cls current migrateAfterUpdate.
		Stdio stdout nextPutAll: 'ran canvas migration'; lf ] ].
Stdio stdout nextPutAll: 'update complete, saving image'; lf.
Smalltalk snapshot: true andQuit: true
