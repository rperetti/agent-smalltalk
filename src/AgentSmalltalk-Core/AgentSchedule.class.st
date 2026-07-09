"
I am the deliberately small schedule vocabulary for AgentAutomation.
I support only intervals measured in minutes/hours and one local time each
day. I answer the first occurrence strictly after a supplied DateAndTime, so
tests inject time and never sleep.
"
Class {
	#name : 'AgentSchedule',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'amount',
		'dailyTime'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'instance creation' }
AgentSchedule class >> everyMinutes: aNumber [
	self validatePositive: aNumber.
	^ self new
		kind: #minutes;
		amount: aNumber;
		yourself
]

{ #category : 'instance creation' }
AgentSchedule class >> everyHours: aNumber [
	self validatePositive: aNumber.
	^ self new
		kind: #hours;
		amount: aNumber;
		yourself
]

{ #category : 'instance creation' }
AgentSchedule class >> dailyAt: aTime [
	(aTime isKindOf: Time) ifFalse: [
		self error: 'A daily schedule requires a Time' ].
	aTime second = 0 ifFalse: [
		self error: 'Daily schedules use minute precision' ].
	^ self new
		kind: #daily;
		dailyTime: aTime;
		yourself
]

{ #category : 'instance creation' }
AgentSchedule class >> dailyAtHour: anHour minute: aMinute [
	^ self dailyAt: (Time hour: anHour minute: aMinute second: 0)
]

{ #category : 'validation' }
AgentSchedule class >> validatePositive: aNumber [
	(aNumber isInteger and: [ aNumber > 0 ]) ifFalse: [
		self error: 'Schedule interval must be a positive whole number' ]
]

{ #category : 'accessing' }
AgentSchedule >> kind: aSymbol [
	kind := aSymbol
]

{ #category : 'accessing' }
AgentSchedule >> amount: aNumber [
	amount := aNumber
]

{ #category : 'accessing' }
AgentSchedule >> dailyTime: aTime [
	dailyTime := aTime
]

{ #category : 'accessing' }
AgentSchedule >> kind [
	^ kind
]

{ #category : 'accessing' }
AgentSchedule >> amount [
	^ amount
]

{ #category : 'accessing' }
AgentSchedule >> dailyTime [
	^ dailyTime
]

{ #category : 'scheduling' }
AgentSchedule >> nextAfter: aDateAndTime [
	kind = #minutes ifTrue: [ ^ aDateAndTime + amount minutes ].
	kind = #hours ifTrue: [ ^ aDateAndTime + amount hours ].
	kind = #daily ifTrue: [ ^ self nextDailyAfter: aDateAndTime ].
	self error: 'Unknown schedule kind: ' , kind printString
]

{ #category : 'scheduling' }
AgentSchedule >> nextDailyAfter: aDateAndTime [
	| candidate |
	candidate := DateAndTime
		year: aDateAndTime year
		month: aDateAndTime month
		day: aDateAndTime dayOfMonth
		hour: dailyTime hour
		minute: dailyTime minute
		second: dailyTime second
		offset: aDateAndTime offset.
	candidate > aDateAndTime ifTrue: [ ^ candidate ].
	^ candidate + 1 day
]

{ #category : 'printing' }
AgentSchedule >> describe [
	kind = #daily ifTrue: [
		^ 'daily at ' , (dailyTime print24 first: 5) ].
	kind = #minutes ifTrue: [
		^ 'every ' , amount printString , ' '
			, (amount = 1 ifTrue: [ 'minute' ] ifFalse: [ 'minutes' ]) ].
	kind = #hours ifTrue: [
		^ 'every ' , amount printString , ' '
			, (amount = 1 ifTrue: [ 'hour' ] ifFalse: [ 'hours' ]) ].
	^ 'unknown schedule'
]

{ #category : 'printing' }
AgentSchedule >> printOn: aStream [
	aStream nextPutAll: self describe
]
