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
		ifNotNil: [ fact body ]
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
	| value |
	value := self at: aSymbol.
	value isUnknown ifTrue: [ ^ value ].
	^ [ (value select: [ :c | c isDigit or: [ '.-' includes: c ] ]) asNumber
			ifNil: [ AgentUnknown key: aSymbol ] ]
		on: Error
		do: [ :e | AgentUnknown key: aSymbol ]
]
