"
Headless tests for the transient knowledge catalog. Live canvas objects, tool
classes, and automations remain the stores; catalog projections are bounded,
request-local views over them.
"
Class {
	#name : 'AgentKnowledgeCatalogTest',
	#superclass : 'TestCase',
	#instVars : [
		'madeTools'
	],
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentKnowledgeCatalogTest >> setUp [
	super setUp.
	AgentScheduler reset.
	AgentAutomation resetRegistry.
	AgentCanvas reset.
	AgentAutomationTestProbe purpose: 'exercise catalog discovery'.
	madeTools := OrderedCollection new
]

{ #category : 'running' }
AgentKnowledgeCatalogTest >> tearDown [
	madeTools do: [ :tool |
		(Smalltalk globals includesKey: tool name) ifTrue: [ tool removeFromSystem ] ].
	AgentAutomation resetRegistry.
	AgentScheduler reset.
	AgentCanvas reset.
	super tearDown
]

{ #category : 'support' }
AgentKnowledgeCatalogTest >> defineToolNamed: aSymbol purpose: aString [
	| tool |
	tool := AgentTool defineNamed: aSymbol purpose: aString.
	madeTools add: tool.
	^ tool
]

{ #category : 'tests' }
AgentKnowledgeCatalogTest >> testCatalogProjectsLiveFactsWithoutOwningThem [
	| fact first second |
	fact := AgentFact key: #city body: 'Tokyo'.
	first := (AgentKnowledgeCatalog snapshot projectionsOfKind: #fact) first.
	second := (AgentKnowledgeCatalog snapshot projectionsOfKind: #fact) first.
	self assert: first key equals: #city.
	self assert: first summary equals: 'Tokyo'.
	self assert: first source identicalTo: fact.
	self deny: first == second
]

{ #category : 'tests' }
AgentKnowledgeCatalogTest >> testCatalogMarksSelectedObjects [
	| note projection |
	note := AgentNote question: 'What happened?' answer: 'A useful answer'.
	AgentCanvas current selectWidgets: { note }.
	projection := (AgentKnowledgeCatalog snapshot projectionsOfKind: #note) first.
	self assert: projection selected.
	self assert: projection source identicalTo: note
]

{ #category : 'tests' }
AgentKnowledgeCatalogTest >> testProjectionBoundsCopiedContent [
	| body projection |
	body := String new: 3000 withAll: $x.
	AgentFact key: #large body: body.
	projection := (AgentKnowledgeCatalog snapshot projectionsOfKind: #fact) first.
	self assert: projection contentTruncated.
	self assert: projection content size equals: AgentKnowledgeProjection maxContentCharacters.
	self assert: (projection content endsWith: '[truncated]')
]

{ #category : 'tests' }
AgentKnowledgeCatalogTest >> testSearchIsCaseInsensitiveRankedAndKindScoped [
	| results |
	AgentFact key: #city body: 'Tokyo'.
	AgentFact key: #trip body: 'A future visit to city parks'.
	AgentNote question: 'City guide' answer: 'Kyoto'.
	results := AgentKnowledgeCatalog snapshot
		search: 'CITY'
		kinds: #(fact)
		limit: 10.
	self assert: results size equals: 2.
	self assert: results first key equals: #city.
	self assert: results second key equals: #trip.
	self assert: (results allSatisfy: [ :projection | projection kind = #fact ])
]

{ #category : 'tests' }
AgentKnowledgeCatalogTest >> testToolCardDoesNotDuplicateCapabilityProjection [
	| tool catalog capabilities |
	tool := self defineToolNamed: #KnowledgeCatalogTestTool purpose: 'retrieve a bounded result'.
	tool class compile: 'fetch ^ 42'.
	catalog := AgentKnowledgeCatalog snapshot.
	capabilities := catalog projectionsOfKind: #capability.
	self assert: (capabilities count: [ :projection | projection source == tool ]) equals: 1.
	self deny: (catalog projections anySatisfy: [ :projection |
		projection source isKindOf: AgentToolCard ])
]

{ #category : 'tests' }
AgentKnowledgeCatalogTest >> testRegisteredAutomationContributesOneProjection [
	| automation projections |
	automation := AgentAutomationTestProbe new
		schedule: (AgentSchedule everyMinutes: 5) at: DateAndTime now;
		register;
		yourself.
	projections := AgentKnowledgeCatalog snapshot projectionsOfKind: #automation.
	self assert: (projections count: [ :projection |
		projection source == automation ]) equals: 1
]
