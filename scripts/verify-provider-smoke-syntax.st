"Parse every paid evaluation without running it. This belongs in the
deterministic verification path: provider calls remain opt-in, but a syntax
mistake must still fail a local release signal."
| root names passed |
root := FileLocator image asFileReference parent parent.
names := #(
	'smoke-fact-widget.st'
	'smoke-widget.st'
	'smoke-modify.st'
	'smoke-textfield.st'
	'smoke-facts.st'
	'smoke-tools.st'
	'smoke-selection.st'
	'smoke-reactive.st').
passed := true.
names do: [ :name |
	[ RBParser parseExpression: (root / 'scripts' / name) contents asString.
		Stdio stdout nextPutAll: 'PARSE OK: ' , name; lf ]
		on: Error
		do: [ :error |
			passed := false.
			Stdio stdout nextPutAll: 'PARSE FAILED: ' , name , ' ('
				, error class name , ')'; lf ] ].
passed
	ifTrue: [ Smalltalk exitSuccess ]
	ifFalse: [ Smalltalk exitFailure ]
