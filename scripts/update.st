"Reload a preflighted source candidate into a staged image, then save only after
the generated build manifest verifies. update.sh supplies AGENT_UPDATE_MANIFEST
and promotes this staged image only when this process exits successfully."
| manifest updateError |
manifest := OSEnvironment current at: 'AGENT_UPDATE_MANIFEST' ifAbsent: [ nil ].
updateError := nil.
manifest ifNil: [ updateError := 'missing AGENT_UPDATE_MANIFEST' ].
updateError ifNil: [
	[ AgentUpdater updateFromSrc: AgentUpdater srcDirectory expectingManifest: manifest.
		AgentUpdater finalizeVerifiedUpdate: manifest ]
		on: Error
		do: [ :error |
			updateError := error class name , ': ' , (error messageText ifNil: [ '' ]) ] ].
updateError
	ifNotNil: [
		Stdio stdout nextPutAll: 'UPDATE_FAILED: ' , updateError; lf.
		Smalltalk exitFailure ]
	ifNil: [
		Stdio stdout nextPutAll: 'UPDATE_OK ' , manifest; lf.
		Smalltalk snapshot: true andQuit: true ]
