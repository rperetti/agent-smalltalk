"Reload the AgentSmalltalk packages from src/ into the image and save.
Headless path (image file not held by a session); the live-session path is
AgentRemote's /update endpoint, tried first by update.sh."
AgentUpdater updateFromSrc.
Stdio stdout nextPutAll: 'update complete, saving image'; lf.
Smalltalk snapshot: true andQuit: true
