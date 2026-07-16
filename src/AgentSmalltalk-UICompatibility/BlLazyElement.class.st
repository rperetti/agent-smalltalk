"
Compatibility placeholder for Album's dormant asynchronous-adornment strategy.
The pinned Album version still compiles that strategy against BlLazyElement,
although the matching Bloc runtime no longer provides it. Agent Smalltalk uses
Album's synchronous editor path; attempting the unsupported asynchronous path
fails explicitly instead of leaving an undeclared global in the image.
"
Class {
	#name : 'BlLazyElement',
	#superclass : 'BlElement',
	#category : 'AgentSmalltalk-UICompatibility',
	#package : 'AgentSmalltalk-UICompatibility'
}

{ #category : 'unsupported Album compatibility' }
BlLazyElement >> elementBuilder: aBlock [
	self error: 'Album asynchronous adornments require a Bloc runtime that is not part of the production UI closure'
]

{ #category : 'unsupported Album compatibility' }
BlLazyElement >> in: aBlock [
	self error: 'Album asynchronous adornments require a Bloc runtime that is not part of the production UI closure'
]
