"Reload the AgentSmalltalk packages from src/ into the image and save.
Headless path (image file not held by a session); the live-session path is
AgentRemote's /update endpoint, tried first by update.sh.

GUARDED: a silent load failure that leaves stale code running is far more
dangerous than a loud crash (a single syntax error once aborted every load
for many commits while update.sh reported success). We catch load errors,
verify sentinel selectors across all packages, and print UPDATE_OK only when
the load is genuinely complete -- update.sh requires that token AND a clean
exit before trusting the update."
| loadError |
loadError := nil.
[ AgentUpdater updateFromSrc ]
	on: Error
	do: [ :e |
		loadError := e class name , ': ' , (e messageText ifNil: [ '' ]) ].
loadError ifNotNil: [
	Stdio stdout nextPutAll: 'UPDATE_FAILED load error: ' , loadError; lf.
	Smalltalk snapshot: false andQuit: 1 ].
"Sentinels: one live selector per package. A compile error aborts its
containing class's load, so a missing sentinel means an incomplete update."
(AgentUpdater verifySentinels)
	ifFalse: [
		Stdio stdout nextPutAll: 'UPDATE_FAILED verification: sentinel selectors missing'; lf.
		Smalltalk snapshot: false andQuit: 1 ].
Stdio stdout nextPutAll: 'UPDATE_OK saving image'; lf.
Smalltalk snapshot: true andQuit: true
