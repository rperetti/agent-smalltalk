"Load everything including Bloc and the UI, then save the image."
| root |
root := FileLocator image asFileReference parent parent.
Metacello new
	baseline: 'AgentSmalltalk';
	repository: 'tonel://' , (root / 'src') fullName;
	onConflictUseIncoming;
	load: 'default'.
Smalltalk snapshot: true andQuit: true
