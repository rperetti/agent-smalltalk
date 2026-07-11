"Load Bloc, Toplo, Album, and Alexandrie's full upstream defaults into the
current image. This is deliberately for a disposable development image only;
scripts/load-all.st is the production AgentSmalltalk runtime."
Metacello new
	baseline: 'Alexandrie';
	repository: 'github://pharo-graphics/Alexandrie:d3185a6f5e4041a2054025c24a5120fd0108b164/src';
	onConflictUseLoaded;
	load: 'development'.
Metacello new
	baseline: 'Bloc';
	repository: 'github://pharo-graphics/Bloc:a863816b9e526826d66286d871fef7042b03f546/src';
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
