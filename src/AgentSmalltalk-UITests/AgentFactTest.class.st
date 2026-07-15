"
Headless tests for the sticky-note memory: creation, keyed dedup, in-place
updates, and exclusion from the always-sent canvas context. Uses the canvas in
headless mode (detached content, no space).
"
Class {
	#name : 'AgentFactTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentFactTest >> setUp [
	super setUp.
	AgentCanvas reset
]

{ #category : 'running' }
AgentFactTest >> tearDown [
	AgentCanvas reset.
	super tearDown
]

{ #category : 'tests' }
AgentFactTest >> testFactAppearsOnCanvas [
	AgentFact key: #city body: 'lives in Porto Alegre'.
	self assert: AgentCanvas current facts size equals: 1.
	self assert: AgentCanvas current toolWidgets isEmpty
]

{ #category : 'tests' }
AgentFactTest >> testKeyedFactIsDeduplicated [
	AgentFact key: #city body: 'lives in Porto Alegre'.
	AgentFact key: #city body: 'lives in Madrid'.
	self assert: AgentCanvas current facts size equals: 1.
	self assert: AgentCanvas current facts first body equals: 'lives in Madrid'
]

{ #category : 'tests' }
AgentFactTest >> testKeylessFactsAccumulate [
	AgentFact body: 'prefers espresso'.
	AgentFact body: 'has two cats'.
	self assert: AgentCanvas current facts size equals: 2
]

{ #category : 'tests' }
AgentFactTest >> testDescribeIncludesKeyAndBody [
	| fact |
	fact := AgentFact key: #userName body: 'name is Rodrigo'.
	self assert: fact describe equals: 'fact[userName]: name is Rodrigo'
]

{ #category : 'tests' }
AgentFactTest >> testFactWithKeyLookup [
	AgentFact key: #city body: 'lives in Porto Alegre'.
	self assert: (AgentCanvas current factWithKey: #city) notNil.
	self assert: (AgentCanvas current factWithKey: #shoeSize) isNil
]

{ #category : 'tests' }
AgentFactTest >> testContextDescriptionExcludesFacts [
	| context |
	AgentFact key: #city body: 'lives in Porto Alegre'.
	AgentWidget new position: 100 @ 100; in: [ :w | AgentCanvas current addWidget: w ].
	context := AgentCanvas current contextDescription.
	self deny: (context includesSubstring: '## Known facts').
	self deny: (context includesSubstring: 'fact[city]: lives in Porto Alegre').
	self assert: (context includesSubstring: '## Widgets on the canvas')
]

{ #category : 'tests' }
AgentFactTest >> testFactsAreNotToolWidgets [
	AgentFact key: #city body: 'x'.
	AgentWidget new in: [ :w | AgentCanvas current addWidget: w ].
	self assert: AgentCanvas current facts size equals: 1.
	self assert: AgentCanvas current toolWidgets size equals: 1
]
