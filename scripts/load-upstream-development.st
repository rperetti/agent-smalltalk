"Load Bloc, Toplo, Album, and Alexandrie's full upstream defaults into the
current image. This is deliberately for a disposable development image only;
scripts/load-all.st is the production AgentSmalltalk runtime."
Metacello new
	baseline: 'Alexandrie';
	repository: 'github://pharo-graphics/Alexandrie:4083bf84343b878521ebb4a26b5aa76cf28fa490/src';
	onConflictUseLoaded;
	load: 'development'.
Metacello new
	baseline: 'Bloc';
	repository: 'github://pharo-graphics/Bloc:041defd538e3e1caf17060eb0f44062c5c4c1a8f/src';
	onConflictUseLoaded;
	load.
Metacello new
	baseline: 'Album';
	repository: 'github://pharo-graphics/Album:a20f74b190c41fabb2b2b27bbdaa0eb41c261d33/src';
	onConflictUseLoaded;
	load.
Metacello new
	baseline: 'Toplo';
	repository: 'github://pharo-graphics/Toplo:685e2497e6fff39682c4e66eebb7d33443c3f341/src';
	onConflictUseLoaded;
	load.
Smalltalk snapshot: true andQuit: true
