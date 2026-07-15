"Verify that the disposable image loaded the exact generated candidate marker.
test.sh runs this only when AGENT_UPDATE_MANIFEST is supplied by update.sh."
| manifest |
manifest := OSEnvironment current at: 'AGENT_UPDATE_MANIFEST' ifAbsent: [ nil ].
(AgentUpdater verifyLoadedManifest: manifest)
	ifTrue: [
		Stdio stdout nextPutAll: 'UPDATE_PREFLIGHT_OK ' , manifest; lf.
		Smalltalk exitSuccess ]
	ifFalse: [
		Stdio stdout nextPutAll: 'UPDATE_PREFLIGHT_FAILED'; lf.
		Smalltalk exitFailure ]
