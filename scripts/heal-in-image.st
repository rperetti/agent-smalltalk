"HEAL -- paste and run (select all, Do it) in a Playground inside the RUNNING
Agent image. Use when the image file got poisoned (stale SSL sessions) or a
GUI save overwrote an update:
1) neutralizes stale SSL sessions whose finalizers crash headless startup
   (ZdcPluginSSLSession>>destroy is a no-op once handle is nil);
2) pulls the latest tooling from src/ into THIS session -- no file swapping,
   so nothing can be clobbered by a later save;
3) runs migrations and saves."
| src |
(Smalltalk globals at: #ZdcPluginSSLSession ifAbsent: [ nil ]) ifNotNil: [ :cls |
	cls allInstancesDo: [ :s |
		[ s instVarNamed: #handle put: nil ] on: Error do: [ :e |  ] ] ].
src := FileLocator image asFileReference parent parent / 'src'.
#('AgentSmalltalk-Core' 'AgentSmalltalk-UI' 'AgentSmalltalk-Tests' 'AgentSmalltalk-UITests' 'BaselineOfAgentSmalltalk')
	do: [ :pkgName |
		| reader |
		reader := TonelReader on: src fileName: pkgName.
		reader loadDefinitions.
		MCPackageLoader updatePackage: (MCPackage named: pkgName) withSnapshot: reader snapshot ].
AgentCanvas current migrateAfterUpdate.
Smalltalk snapshot: true andQuit: false.
'healed + updated'
