"
I describe an inference-provider failure in a form the gateway can handle
without knowing a provider's HTTP error format. Retryability applies only to
the remote inference request: no local tool has run when I am signalled.
"
Class {
	#name : 'AgentInferenceProviderError',
	#superclass : 'Error',
	#instVars : [
		'retryable',
		'statusCode'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'signalling' }
AgentInferenceProviderError class >> signal: aString retryable: aBoolean statusCode: anIntegerOrNil [
	^ self new
		messageText: aString;
		retryable: aBoolean;
		statusCode: anIntegerOrNil;
		signal
]

{ #category : 'accessing' }
AgentInferenceProviderError >> retryable [
	^ retryable = true
]

{ #category : 'accessing' }
AgentInferenceProviderError >> retryable: aBoolean [
	retryable := aBoolean = true
]

{ #category : 'accessing' }
AgentInferenceProviderError >> statusCode [
	^ statusCode
]

{ #category : 'accessing' }
AgentInferenceProviderError >> statusCode: anIntegerOrNil [
	statusCode := anIntegerOrNil
]
