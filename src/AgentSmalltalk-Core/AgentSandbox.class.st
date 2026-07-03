"
I evaluate LLM-generated Pharo code in the running image and answer a plain-text
report the model can act on: 'RESULT: <printString>' on success, 'ERROR: <report>'
on failure. I also keep rotating image backups so a bad evaluation is recoverable.
"
Class {
	#name : 'AgentSandbox',
	#superclass : 'Object',
	#instVars : [
		'timeoutSeconds'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'initialization' }
AgentSandbox >> initialize [
	super initialize.
	timeoutSeconds := 10
]

{ #category : 'accessing' }
AgentSandbox >> timeoutSeconds [
	^ timeoutSeconds
]

{ #category : 'accessing' }
AgentSandbox >> timeoutSeconds: aNumber [
	timeoutSeconds := aNumber
]

{ #category : 'evaluating' }
AgentSandbox >> evaluate: aString [
	"Evaluate Pharo source and answer a text report for the LLM."
	^ [ self basicEvaluate: aString ]
		valueWithin: timeoutSeconds seconds
		onTimeout: [
			'ERROR: evaluation timed out after ' , timeoutSeconds printString
			, ' seconds. Avoid long-running or infinite loops.' ]
]

{ #category : 'evaluating' }
AgentSandbox >> basicEvaluate: aString [
	^ [ 'RESULT: ' , (self safePrint: (Smalltalk compiler evaluate: aString)) ]
		on: Error
		do: [ :e | self errorReportFor: e ]
]

{ #category : 'evaluating' }
AgentSandbox >> safePrint: anObject [
	^ [ anObject printString ]
		on: Error
		do: [ :e | 'a ' , anObject class name , ' (printString failed: ' , e messageText , ')' ]
]

{ #category : 'evaluating' }
AgentSandbox >> errorReportFor: anError [
	^ String streamContents: [ :s |
		s << 'ERROR: ' << anError class name << ': '
			<< (anError messageText ifNil: [ 'no message text' ]).
		s cr.
		s << 'Stack (top frames):'.
		s cr.
		[ | stack |
			stack := anError signalerContext stack.
			(stack first: (8 min: stack size)) do: [ :ctx |
				s << '  ' << ctx printString.
				s cr ] ]
			on: Error
			do: [ :e2 | s << '  (stack unavailable)' ] ]
]

{ #category : 'safety' }
AgentSandbox >> backupImage [
	"Copy the image file (i.e. the last snapshot) to a rotating backup, keeping the newest 5.
	Crude but effective: a corrupted image is recoverable by restoring a backup file."
	| imageFile dir backups target |
	imageFile := FileLocator image asFileReference.
	imageFile exists ifFalse: [ ^ nil ].
	dir := imageFile parent / 'backups'.
	dir ensureCreateDirectory.
	target := dir / ('agent-backup-' , DateAndTime now asUnixTime printString , '.image').
	target exists ifTrue: [ ^ target ].
	imageFile copyTo: target.
	backups := ((dir children select: [ :f | f basename beginsWith: 'agent-backup-' ])
		asSortedCollection: [ :a :b | a basename < b basename ]) asOrderedCollection.
	[ backups size > 5 ] whileTrue: [
		backups first ensureDelete.
		backups removeFirst ].
	^ target
]
