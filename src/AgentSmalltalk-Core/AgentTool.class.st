"
I am the base class for the agent's own reusable capabilities -- tools it
writes once and reuses instead of re-deriving the same fetch/parse/compute on
every request. A tool is an ordinary class with class-side capability methods
(the stateless-service default); subclassing me makes it discoverable
(AgentTool allSubclasses) and lists it in the agent's context under
'## Capabilities you've built'.

The agent creates tools via the blessed helper (insulated from Pharo
class-builder API drift):
    AgentTool defineNamed: #WeatherService purpose: 'fetch weather for a city'.
    WeatherService class compile: 'fetchFor: aCity  ...'.
Then reuses them:  WeatherService fetchFor: 'Tokyo'.

Generated tools live in the AgentSmalltalk-Tools package, created live and
NOT tracked in src/, so update.sh never wipes them -- they persist with the
image like generated widgets.
"
Class {
	#name : 'AgentTool',
	#superclass : 'Object',
	#classInstVars : [
		'purpose'
	],
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'creating' }
AgentTool class >> defineNamed: aSymbol purpose: aPurpose [
	"Create a stateless tool (class-side capability methods only)."
	^ self defineNamed: aSymbol slots: #() purpose: aPurpose
]

{ #category : 'creating' }
AgentTool class >> defineNamed: aSymbol slots: slotSymbols purpose: aPurpose [
	"Blessed tool-class creation. Slots are for the rare stateful tool;
	most tools are stateless services and pass #()."
	| toolClass |
	toolClass := AgentTool << aSymbol asSymbol
		slots: slotSymbols;
		package: 'AgentSmalltalk-Tools';
		install.
	toolClass purpose: aPurpose.
	self summonCardFor: toolClass.
	^ toolClass
]

{ #category : 'accessing' }
AgentTool class >> purpose [
	"Class-instance variable: each subclass carries its own purpose."
	^ purpose
]

{ #category : 'accessing' }
AgentTool class >> purpose: aString [
	purpose := aString
]

{ #category : 'accessing' }
AgentTool class >> tools [
	"All defined tools (leaf capability classes), name-sorted."
	^ self allSubclasses asSortedCollection: [ :a :b | a name < b name ]
]

{ #category : 'accessing' }
AgentTool class >> capabilitySelectors [
	"The class-side methods a subclass defines itself -- its capability API.
	Excludes inherited base methods (purpose, defineNamed:..., etc.), which
	live on AgentTool's metaclass, not the subclass's."
	^ self class selectors asSortedCollection asArray
]

{ #category : 'context' }
AgentTool class >> contextListing [
	"The '## Capabilities you've built' section the gateway appends to the
	system prompt: every tool with its purpose and class-side capability
	selectors, so the agent reuses instead of rebuilding."
	^ String streamContents: [ :s |
		s << '## Capabilities you''ve built'.
		s cr.
		self tools
			ifEmpty: [
				s << '(none yet -- build a tool for any reusable capability instead of re-deriving it)'.
				s cr ]
			ifNotEmpty: [ :ts |
				ts do: [ :tool |
					s << '- ' << tool name << ' -- ' << (tool purpose ifNil: [ 'no purpose' ]).
					s cr.
					tool capabilitySelectors ifNotEmpty: [ :sels |
						s << '    ' << (sels inject: '' into: [ :acc :each | acc , each , ' ' ]).
						s cr ] ] ] ]
]

{ #category : 'cards' }
AgentTool class >> summonCardFor: toolClass [
	"Give the tool a visible card (bottom-right toolbox). Guarded global so
	Core does not depend on UI; a no-op if the card class is not loaded."
	(Smalltalk globals at: #AgentToolCard ifAbsent: [ ^ self ])
		ifNotNil: [ :cardClass |
			[ cardClass summonFor: toolClass ] on: Error do: [ :e |  ] ]
]
