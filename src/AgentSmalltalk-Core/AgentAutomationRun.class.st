"
I am one compact, durable history entry for an AgentAutomation. Histories are
bounded by their owner, so a long-lived image does not grow without limit.
"
Class {
	#name : 'AgentAutomationRun',
	#superclass : 'Object',
	#instVars : [
		'status',
		'startedAt',
		'finishedAt',
		'summary'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'instance creation' }
AgentAutomationRun class >> status: aSymbol startedAt: start finishedAt: finish summary: aString [
	^ self new
		status: aSymbol;
		startedAt: start;
		finishedAt: finish;
		summary: aString;
		yourself
]

{ #category : 'instance creation' }
AgentAutomationRun class >> missedAt: aDateAndTime [
	^ self
		status: #missed
		startedAt: aDateAndTime
		finishedAt: aDateAndTime
		summary: 'missed while the image was closed'
]

{ #category : 'accessing' }
AgentAutomationRun >> status: aSymbol [
	status := aSymbol
]

{ #category : 'accessing' }
AgentAutomationRun >> startedAt: aDateAndTime [
	startedAt := aDateAndTime
]

{ #category : 'accessing' }
AgentAutomationRun >> finishedAt: aDateAndTime [
	finishedAt := aDateAndTime
]

{ #category : 'accessing' }
AgentAutomationRun >> summary: aString [
	summary := aString asString
]

{ #category : 'accessing' }
AgentAutomationRun >> status [
	^ status
]

{ #category : 'accessing' }
AgentAutomationRun >> startedAt [
	^ startedAt
]

{ #category : 'accessing' }
AgentAutomationRun >> finishedAt [
	^ finishedAt
]

{ #category : 'accessing' }
AgentAutomationRun >> summary [
	^ summary ifNil: [ '' ]
]

{ #category : 'printing' }
AgentAutomationRun >> describe [
	^ status asString , ': ' , self summary
]

{ #category : 'printing' }
AgentAutomationRun >> printOn: aStream [
	aStream nextPutAll: self describe
]
