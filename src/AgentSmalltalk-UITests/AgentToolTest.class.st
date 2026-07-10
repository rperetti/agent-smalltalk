"
Headless tests for the agent's self-built tools: creation via the blessed
helper, discoverability, class-side capability listing, the context section,
and the auto-summoned toolbox card (kept out of widget context).
Created tool classes are removed in tearDown so the image stays clean.
"
Class {
	#name : 'AgentToolTest',
	#superclass : 'TestCase',
	#instVars : [
		'made'
	],
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'running' }
AgentToolTest >> setUp [
	super setUp.
	AgentCanvas reset.
	made := OrderedCollection new
]

{ #category : 'running' }
AgentToolTest >> tearDown [
	made do: [ :cls | (Smalltalk globals includesKey: cls name)
		ifTrue: [ cls removeFromSystem ] ].
	AgentCanvas reset.
	super tearDown
]

{ #category : 'running' }
AgentToolTest >> define: aSymbol purpose: aString [
	| cls |
	cls := AgentTool defineNamed: aSymbol purpose: aString.
	made add: cls.
	^ cls
]

{ #category : 'tests' }
AgentToolTest >> testDefineCreatesToolWithPurpose [
	| tool |
	tool := self define: #TestWeatherTool purpose: 'weather for a city'.
	self assert: (tool inheritsFrom: AgentTool).
	self assert: tool purpose equals: 'weather for a city'.
	self assert: tool package name equals: 'AgentSmalltalk-Tools'
]

{ #category : 'tests' }
AgentToolTest >> testDefineStatefulToolWithSlots [
	| tool |
	tool := AgentTool
		defineNamed: #TestStatefulTool
		slots: #(cache timestamp)
		purpose: 'remember a cached result'.
	made add: tool.
	self assert: tool instVarNames equals: #('cache' 'timestamp').
	self assert: tool purpose equals: 'remember a cached result'
]

{ #category : 'tests' }
AgentToolTest >> testToolIsDiscoverable [
	| tool |
	tool := self define: #TestDiscoverTool purpose: 'x'.
	self assert: (AgentTool tools includes: tool)
]

{ #category : 'tests' }
AgentToolTest >> testCapabilitySelectorsAreClassSideOnly [
	| tool |
	tool := self define: #TestApiTool purpose: 'x'.
	tool class compile: 'fetchFor: aCity ^ aCity size'.
	"The agent-compiled class-side method shows; inherited base methods
	(purpose, defineNamed:...) do not."
	self assert: (tool capabilitySelectors includes: #fetchFor:).
	self deny: (tool capabilitySelectors includes: #purpose).
	self deny: (tool capabilitySelectors includes: #defineNamed:purpose:)
]

{ #category : 'tests' }
AgentToolTest >> testToolAutomationActionRequiresExplicitOptIn [
	| tool |
	tool := self define: #TestUnscheduledTool purpose: 'needs an argument'.
	self
		should: [ tool runAutomatedAction ]
		raise: Error.
	tool class compile: 'runAutomatedAction
	^ AgentAutomationResult unchanged: ''ran tool action'''.
	self
		assert: tool runAutomatedAction summary
		equals: 'ran tool action'
]

{ #category : 'tests' }
AgentToolTest >> testContextListingIncludesToolAndPurpose [
	| listing |
	(self define: #TestListedTool purpose: 'fetch the thing') class
		compile: 'grab ^ 42'.
	listing := AgentTool contextListing.
	self assert: (listing includesSubstring: 'Capabilities you''ve built').
	self assert: (listing includesSubstring: 'TestListedTool').
	self assert: (listing includesSubstring: 'fetch the thing').
	self assert: (listing includesSubstring: 'grab')
]

{ #category : 'tests' }
AgentToolTest >> testEmptyContextInvitesToolCreation [
	| listing |
	listing := AgentTool contextListing.
	self assert: (listing includesSubstring: 'Capabilities you''ve built').
	self assert: (listing includesSubstring: 'none yet').
	self assert: (listing includesSubstring: 'build a tool')
]

{ #category : 'tests' }
AgentToolTest >> testDefineSummonsOneCard [
	| tool cards |
	tool := self define: #TestCardTool purpose: 'x'.
	cards := AgentCanvas current widgets select: [ :w | w isKindOf: AgentToolCard ].
	self assert: cards size equals: 1.
	self assert: cards first toolClass identicalTo: tool.
	"Re-defining the same tool does not add a second card."
	AgentTool summonCardFor: tool.
	self assert: (AgentCanvas current widgets count: [ :w | w isKindOf: AgentToolCard ]) equals: 1
]

{ #category : 'tests' }
AgentToolTest >> testDeletingCardKeepsToolDiscoverable [
	| tool card |
	tool := self define: #TestDurableTool purpose: 'survives its card'.
	card := AgentCanvas current widgets
		detect: [ :w | w isKindOf: AgentToolCard ].
	card removeFromParent.
	self assert: (AgentTool tools includes: tool).
	self assert: (AgentTool contextListing includesSubstring: 'TestDurableTool')
]

{ #category : 'tests' }
AgentToolTest >> testToolCardPlacementPlanTargetsBottomRight [
	self assert: AgentToolCard nextPosition equals: 940 @ 600.
	self define: #TestCornerToolOne purpose: 'one'.
	self assert: AgentToolCard nextPosition equals: 956 @ 622
]

{ #category : 'tests' }
AgentToolTest >> testToolCardPurposeWrapsAndTracksCardWidth [
	| card purpose |
	self define: #TestWrappingTool purpose:
		'a deliberately long service purpose that needs more than one visual line'.
	card := AgentCanvas current widgets
		detect: [ :w | w isKindOf: AgentToolCard ].
	purpose := card instVarNamed: #purposeLabel.
	self assert: purpose isMultiLine.
	self assert: purpose constraints horizontal resizer isMatchParent.
	self assert: purpose constraints vertical resizer isFitContent.
	self assert: card constraints vertical resizer isFitContent
]

{ #category : 'tests' }
AgentToolTest >> testToolCardRepairMigratesOldFixedLabel [
	| card purpose |
	self define: #TestRepairTool purpose: 'a purpose that should wrap'.
	card := AgentCanvas current widgets
		detect: [ :w | w isKindOf: AgentToolCard ].
	purpose := card instVarNamed: #purposeLabel.
	card extent: 200 @ 84.
	purpose beMonoLine.
	purpose constraintsDo: [ :c | c horizontal exact: 184 ].
	AgentCanvas current migrateAfterUpdate.
	self assert: purpose isMultiLine.
	self assert: purpose constraints horizontal resizer isMatchParent.
	self assert: purpose constraints vertical resizer isFitContent.
	self assert: card constraints vertical resizer isFitContent
]

{ #category : 'tests' }
AgentToolTest >> testToolCardResizeTakesBothDimensionsAndKeepsWrap [
	"Dragging the grip takes explicit control of BOTH width and height (the
	initial vFitContent auto-size is dropped), while the purpose label still
	matches the card width so it reflows rather than clipping."
	| card purpose |
	self define: #TestResizeTool purpose:
		'a long service purpose that should re-wrap when the card is narrowed'.
	card := AgentCanvas current widgets
		detect: [ :w | w isKindOf: AgentToolCard ].
	card resizeTo: 170 @ 400.
	self deny: card constraints vertical resizer isFitContent.
	purpose := card instVarNamed: #purposeLabel.
	self assert: purpose isMultiLine.
	self assert: purpose constraints horizontal resizer isMatchParent
]

{ #category : 'tests' }
AgentToolTest >> testToolCardIsOutOfWidgetContext [
	self define: #TestHiddenCardTool purpose: 'x'.
	self deny: (AgentCanvas current contextDescription includesSubstring: 'TestHiddenCardTool')
]

{ #category : 'tests' }
AgentToolTest >> testGatewaySystemPromptIncludesCapabilities [
	(self define: #TestPromptTool purpose: 'promptable capability') class
		compile: 'go ^ 1'.
	self assert: (AgentGateway new systemPrompt includesSubstring: 'TestPromptTool')
]
