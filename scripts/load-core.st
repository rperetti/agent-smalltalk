"Load the Core group (gateway + sandbox + tests, no Bloc) and save the image."
| root |
root := FileLocator image asFileReference parent parent.
Metacello new
	baseline: 'AgentSmalltalk';
	repository: 'tonel://' , (root / 'src') fullName;
	onConflictUseIncoming;
	load: 'Core'.
Smalltalk snapshot: true andQuit: true
