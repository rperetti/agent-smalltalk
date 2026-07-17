"
I represent one named, image-resident inference policy. I deliberately contain
no credential: an adapter reads its provider API key from the process
environment only when a request is sent.
"
Class {
	#name : 'AgentInferenceProfile',
	#superclass : 'Object',
	#instVars : [
		'name',
		'provider',
		'model',
		'maxOutputTokens',
		'timeoutSeconds',
		'maximumRetries',
		'retryBackoffMilliseconds'
	],
	#classInstVars : [
		'current',
		'profiles'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentInferenceProfile class >> all [
	"The registered image profiles. Their fields are ordinary inspectable
	objects, but credentials remain outside the image."
	self installBuiltInProfiles.
	^ self profiles values asArray
]

{ #category : 'instance creation' }
AgentInferenceProfile class >> current [
	self installBuiltInProfiles.
	^ current ifNil: [
		current := self profiles at: self defaultName.
		current ]
]

{ #category : 'instance creation' }
AgentInferenceProfile class >> current: anInferenceProfile [
	self installBuiltInProfiles.
	current := self register: anInferenceProfile
]

{ #category : 'instance creation' }
AgentInferenceProfile class >> default [
	^ self named: self defaultName provider: 'anthropic'
]

{ #category : 'accessing' }
AgentInferenceProfile class >> defaultName [
	^ 'Default Anthropic'
]

{ #category : 'instance creation' }
AgentInferenceProfile class >> builtInProfiles [
	^ {
		self default.
		self named: 'Default OpenAI' provider: 'openai' }
]

{ #category : 'instance creation' }
AgentInferenceProfile class >> named: aName provider: aProvider [
	^ self new
		name: aName;
		provider: aProvider;
		yourself
]

{ #category : 'accessing' }
AgentInferenceProfile class >> profileNamed: aName [
	| normalized |
	self installBuiltInProfiles.
	normalized := aName asString trimBoth.
	^ self profiles
		at: normalized
		ifAbsent: [ self error: 'No inference profile named ''' , normalized , '''' ]
]

{ #category : 'private' }
AgentInferenceProfile class >> profiles [
	^ profiles ifNil: [ profiles := Dictionary new ]
]

{ #category : 'private' }
AgentInferenceProfile class >> installBuiltInProfiles [
	self builtInProfiles do: [ :profile |
		(self profiles includesKey: profile name) ifFalse: [
			self profiles at: profile name put: profile ] ]
]

{ #category : 'accessing' }
AgentInferenceProfile class >> register: anInferenceProfile [
	(anInferenceProfile isKindOf: self) ifFalse: [
		self error: 'An inference profile must be an AgentInferenceProfile' ].
	anInferenceProfile validate.
	self profiles at: anInferenceProfile name put: anInferenceProfile.
	^ anInferenceProfile
]

{ #category : 'converting' }
AgentInferenceProfile >> asDictionary [
	"A credential-free representation suitable for inspection by a user or the
	agent."
	^ {
		'name' -> self name.
		'provider' -> self provider.
		'model' -> self model.
		'max_output_tokens' -> self maxOutputTokens.
		'timeout_seconds' -> self timeoutSeconds.
		'maximum_retries' -> self maximumRetries.
		'retry_backoff_milliseconds' -> self retryBackoffMilliseconds }
		asDictionary
]

{ #category : 'initialization' }
AgentInferenceProfile >> initialize [
	super initialize.
	name := 'Unnamed inference profile'.
	provider := 'anthropic'.
	model := (AgentInferenceProvider named: provider) defaultModel.
	maxOutputTokens := 8192.
	timeoutSeconds := 180.
	maximumRetries := 2.
	retryBackoffMilliseconds := 250
]

{ #category : 'accessing' }
AgentInferenceProfile >> maxOutputTokens [
	^ maxOutputTokens
]

{ #category : 'accessing' }
AgentInferenceProfile >> maxOutputTokens: aPositiveInteger [
	(aPositiveInteger isInteger and: [ aPositiveInteger > 0 ]) ifFalse: [
		self error: 'Maximum output tokens must be a positive integer' ].
	maxOutputTokens := aPositiveInteger
]

{ #category : 'accessing' }
AgentInferenceProfile >> maximumRetries [
	^ maximumRetries
]

{ #category : 'accessing' }
AgentInferenceProfile >> maximumRetries: aNonNegativeInteger [
	(aNonNegativeInteger isInteger and: [ aNonNegativeInteger >= 0 ]) ifFalse: [
		self error: 'Maximum retries must be a non-negative integer' ].
	maximumRetries := aNonNegativeInteger
]

{ #category : 'accessing' }
AgentInferenceProfile >> model [
	^ model
]

{ #category : 'accessing' }
AgentInferenceProfile >> model: aString [
	(aString isKindOf: String) ifFalse: [ self error: 'Model must be a string' ].
	aString trimBoth isEmpty ifTrue: [ self error: 'Model must not be empty' ].
	model := aString trimBoth
]

{ #category : 'accessing' }
AgentInferenceProfile >> name [
	^ name
]

{ #category : 'accessing' }
AgentInferenceProfile >> name: aString [
	(aString isKindOf: String) ifFalse: [ self error: 'Profile name must be a string' ].
	aString trimBoth isEmpty ifTrue: [ self error: 'Profile name must not be empty' ].
	name := aString trimBoth
]

{ #category : 'printing' }
AgentInferenceProfile >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' (';
		nextPutAll: self name;
		nextPutAll: ': ';
		nextPutAll: self provider;
		nextPutAll: ' / ';
		nextPutAll: self model;
		nextPut: $)
]

{ #category : 'accessing' }
AgentInferenceProfile >> provider [
	^ provider
]

{ #category : 'accessing' }
AgentInferenceProfile >> provider: aString [
	| normalized previousDefault |
	(aString isKindOf: String) ifFalse: [ self error: 'Provider must be a string' ].
	normalized := aString trimBoth asLowercase.
	normalized isEmpty ifTrue: [ self error: 'Provider must not be empty' ].
	previousDefault := provider ifNil: [ nil ] ifNotNil: [
		(AgentInferenceProvider named: provider) defaultModel ].
	AgentInferenceProvider named: normalized.
	provider := normalized.
	(model isNil or: [ model = previousDefault ]) ifTrue: [
		model := (AgentInferenceProvider named: provider) defaultModel ]
]

{ #category : 'accessing' }
AgentInferenceProfile >> retryBackoffMilliseconds [
	^ retryBackoffMilliseconds
]

{ #category : 'accessing' }
AgentInferenceProfile >> retryBackoffMilliseconds: aPositiveInteger [
	(aPositiveInteger isInteger and: [ aPositiveInteger > 0 ]) ifFalse: [
		self error: 'Retry backoff must be a positive integer number of milliseconds' ].
	retryBackoffMilliseconds := aPositiveInteger
]

{ #category : 'accessing' }
AgentInferenceProfile >> timeoutSeconds [
	^ timeoutSeconds
]

{ #category : 'accessing' }
AgentInferenceProfile >> timeoutSeconds: aPositiveInteger [
	(aPositiveInteger isInteger and: [ aPositiveInteger > 0 ]) ifFalse: [
		self error: 'Inference timeout must be a positive integer number of seconds' ].
	timeoutSeconds := aPositiveInteger
]

{ #category : 'validation' }
AgentInferenceProfile >> validate [
	self
		name: name;
		provider: provider;
		model: model;
		maxOutputTokens: maxOutputTokens;
		timeoutSeconds: timeoutSeconds;
		maximumRetries: maximumRetries;
		retryBackoffMilliseconds: retryBackoffMilliseconds.
	^ self
]
