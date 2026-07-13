"
I am the lookup facade over the fact stickies: the blessed way for any code
(generated widgets, the gateway, headless scripts) to read the user's facts
as live values. The canvas remains the single store -- I only query it.
Missing facts answer an AgentUnknown, never nil or a magic string.
"
Class {
	#name : 'AgentKnowledge',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'private' }
AgentKnowledge class >> canvasClass [
	^ Smalltalk globals at: #AgentCanvas ifAbsent: [ nil ]
]

{ #category : 'accessing' }
AgentKnowledge class >> at: aSymbol [
	| canvasClass fact |
	canvasClass := self canvasClass ifNil: [ ^ AgentUnknown key: aSymbol ].
	fact := canvasClass current factWithKey: aSymbol.
	^ fact
		ifNil: [ AgentUnknown key: aSymbol ]
		ifNotNil: [ fact liveBody ]
]

{ #category : 'accessing' }
AgentKnowledge class >> at: aSymbol ifAbsent: aBlock [
	| value |
	value := self at: aSymbol.
	^ value isUnknown ifTrue: [ aBlock value ] ifFalse: [ value ]
]

{ #category : 'accessing' }
AgentKnowledge class >> numberAt: aSymbol [
	"The first number found in the fact body ('budget is 2500' -> 2500),
	or an AgentUnknown when absent or non-numeric."
	| value token |
	value := self at: aSymbol.
	value isUnknown ifTrue: [ ^ value ].
	token := self firstNumberTokenIn: value.
	token ifNil: [ ^ AgentUnknown key: aSymbol ].
	^ [ (token copyWithout: $,) asNumber
			ifNil: [ AgentUnknown key: aSymbol ] ]
		on: Error
		do: [ :e | AgentUnknown key: aSymbol ]
]

{ #category : 'private' }
AgentKnowledge class >> firstNumberTokenIn: aString [
	"Scan one complete number rather than collecting every digit-like character
	in the fact. A token has optional leading minus, optional thousands groups,
	and an optional fractional part."
	| index size start |
	index := 1.
	size := aString size.
	[ index <= size ] whileTrue: [
		((aString at: index) isDigit or: [
			(aString at: index) = $- and: [
				index < size and: [ (aString at: index + 1) isDigit ] ] ])
			ifTrue: [
				start := index.
				(aString at: index) = $- ifTrue: [ index := index + 1 ].
				[ index <= size and: [ (aString at: index) isDigit ] ]
					whileTrue: [ index := index + 1 ].
				[ self hasThousandsGroupAt: index in: aString ] whileTrue: [
					index := index + 4 ].
				(index < size and: [
					(aString at: index) = $. and: [
						(aString at: index + 1) isDigit ] ]) ifTrue: [
					index := index + 1.
					[ index <= size and: [ (aString at: index) isDigit ] ]
						whileTrue: [ index := index + 1 ] ].
				^ aString copyFrom: start to: index - 1 ]
			ifFalse: [ index := index + 1 ] ].
	^ nil
]

{ #category : 'private' }
AgentKnowledge class >> hasThousandsGroupAt: index in: aString [
	^ index + 3 <= aString size and: [
		(aString at: index) = $, and: [
			(aString at: index + 1) isDigit and: [
				(aString at: index + 2) isDigit and: [
					(aString at: index + 3) isDigit ] ] ] ]
]
