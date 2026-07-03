"
I answer the gateway's search_image tool: cheap, structured exploration of the
live image so the LLM spends one round per question instead of hand-writing
reflection snippets (which burn rounds on their own syntax errors).
"
Class {
	#name : 'AgentImageSearch',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'handling' }
AgentImageSearch class >> handle: inputDict [
	| action |
	action := inputDict at: 'action' ifAbsent: [ ^ 'ERROR: missing action' ].
	action = 'find_classes' ifTrue: [
		^ self findClasses: (inputDict at: 'query' ifAbsent: [ '' ]) ].
	action = 'find_selectors' ifTrue: [
		^ self findSelectorsOf: (inputDict at: 'class_name' ifAbsent: [ '' ])
			matching: (inputDict at: 'query' ifAbsent: [ '' ]) ].
	action = 'method_source' ifTrue: [
		^ self sourceOf: (inputDict at: 'class_name' ifAbsent: [ '' ])
			selector: (inputDict at: 'query' ifAbsent: [ '' ]) ].
	^ 'ERROR: unknown action ' , action printString
]

{ #category : 'searching' }
AgentImageSearch class >> findClasses: term [
	| names shown |
	term isEmptyOrNil ifTrue: [ ^ 'ERROR: empty query' ].
	names := ((Smalltalk allClasses
		select: [ :c | c name asLowercase includesSubstring: term asLowercase ])
		collect: [ :c | c name asString ]) asSortedCollection asArray.
	names isEmpty ifTrue: [ ^ 'No classes match ''' , term , '''' ].
	shown := names first: (40 min: names size).
	^ String streamContents: [ :s |
		shown do: [ :n | s nextPutAll: n ] separatedBy: [ s nextPutAll: ', ' ].
		names size > 40 ifTrue: [
			s nextPutAll: ' ... (' , names size printString , ' matches total)' ] ]
]

{ #category : 'searching' }
AgentImageSearch class >> findSelectorsOf: className matching: term [
	| cls sels shown |
	cls := self classNamed: className.
	cls ifNil: [ ^ 'ERROR: no class named ''' , className , '''' ].
	sels := term isEmptyOrNil
		ifTrue: [ cls selectors ]
		ifFalse: [
			cls allSelectors select: [ :s |
				s asString asLowercase includesSubstring: term asLowercase ] ].
	sels := sels asSortedCollection asArray.
	sels isEmpty ifTrue: [
		^ 'No selectors of ' , className , ' match ''' , term , '''' ].
	shown := sels first: (60 min: sels size).
	^ String streamContents: [ :s |
		shown do: [ :sel | s nextPutAll: sel asString ] separatedBy: [ s nextPutAll: ' ' ].
		sels size > 60 ifTrue: [
			s nextPutAll: ' ... (' , sels size printString , ' matches total)' ] ]
]

{ #category : 'searching' }
AgentImageSearch class >> sourceOf: className selector: selString [
	| cls method |
	cls := self classNamed: className.
	cls ifNil: [ ^ 'ERROR: no class named ''' , className , '''' ].
	selString isEmptyOrNil ifTrue: [ ^ 'ERROR: empty selector' ].
	method := cls lookupSelector: selString asSymbol.
	method ifNil: [
		^ 'ERROR: ' , className , ' does not understand #' , selString ].
	^ method sourceCode
]

{ #category : 'private' }
AgentImageSearch class >> classNamed: aString [
	"Accept 'Foo' or 'Foo class' (for class-side lookups)."
	| name |
	aString isEmptyOrNil ifTrue: [ ^ nil ].
	name := aString trimBoth.
	(name endsWith: ' class') ifTrue: [
		^ (Smalltalk globals
			at: (name withoutSuffix: ' class') asSymbol
			ifAbsent: [ nil ]) ifNotNil: [ :c | c class ] ].
	^ Smalltalk globals at: name asSymbol ifAbsent: [ nil ]
]
