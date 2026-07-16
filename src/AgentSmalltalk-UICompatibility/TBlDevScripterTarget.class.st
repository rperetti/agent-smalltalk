"
Compatibility target for two Album extensions that belong to Bloc's optional
Scripter package. The production image does not load that developer package;
the extensions remain loadable and fail clearly if invoked.
"
Class {
	#name : 'TBlDevScripterTarget',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-UICompatibility',
	#package : 'AgentSmalltalk-UICompatibility'
}

{ #category : 'unsupported Album compatibility' }
TBlDevScripterTarget >> onChildFromMessage: aSymbol [
	self error: 'Album Scripter targets require Bloc-Scripter, which is excluded from the production UI closure'
]
