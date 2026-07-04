Extension { #name : 'Object' }

{ #category : '*AgentSmalltalk-Core' }
Object >> isUnknown [
	"Anything can be asked; only AgentUnknown answers true."
	^ false
]
