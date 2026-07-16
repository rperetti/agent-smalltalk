"HEAL / BOOTSTRAP -- paste and run (select all, Do it) in a Playground inside
the RUNNING Agent image. Needed at most once per image: after it runs, the
image listens on localhost:8807 and update.sh reaches live sessions
automatically. Also repairs an image whose stale SSL sessions crash headless
startup."
| src |
(Smalltalk globals at: #ZdcPluginSSLSession ifAbsent: [ nil ]) ifNotNil: [ :cls |
	cls allInstancesDo: [ :s |
		[ s instVarNamed: #handle put: nil ] on: Error do: [ :e |  ] ] ].
src := FileLocator image asFileReference parent parent / 'src'.
#('AgentSmalltalk-Core' 'AgentSmalltalk-UICompatibility' 'AgentSmalltalk-UI' 'AgentSmalltalk-Tests' 'AgentSmalltalk-UITests' 'BaselineOfAgentSmalltalk')
	do: [ :pkgName |
		| reader |
		reader := TonelReader on: src fileName: pkgName.
		reader loadDefinitions.
		MCPackageLoader updatePackage: (MCPackage named: pkgName) withSnapshot: reader snapshot ].
AgentCanvas current migrateAfterUpdate.
Smalltalk snapshot: true andQuit: false.
'healed + updated + listening on :8807'
