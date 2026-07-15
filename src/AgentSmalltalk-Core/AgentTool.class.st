"
I am the base class for the agent's own reusable capabilities -- tools it
writes once and reuses instead of re-deriving the same fetch/parse/compute on
every request. A tool is an ordinary class with class-side capability methods
(the stateless-service default); subclassing me makes it discoverable
(AgentTool allSubclasses). The gateway's bounded dynamic context exposes each
tool's name, purpose, and capability selectors as untrusted data.

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

{ #category : 'knowledge catalog' }
AgentTool class >> contributesToKnowledgeCatalog [
	^ true
]

{ #category : 'knowledge catalog' }
AgentTool class >> knowledgeProjectionWithHandle: aHandle selected: isSelected [
	| toolPurpose details |
	toolPurpose := self purpose ifNil: [ self name ].
	details := String streamContents: [ :stream |
		stream << toolPurpose.
		self capabilitySelectors ifNotEmpty: [ :selectors |
			stream << '; selectors: '.
			selectors
				do: [ :selector | stream << selector asString ]
				separatedBy: [ stream space ] ] ].
	^ AgentKnowledgeProjection
		handle: aHandle
		kind: #capability
		key: self name
		label: self name
		summary: toolPurpose
		content: details
		selected: isSelected
		source: self
]

{ #category : 'automations' }
AgentTool class >> automationActionDescription [
	"Short status text for tools that opt into the zero-argument automation
	contract by overriding #runAutomatedAction class-side."
	^ self purpose ifNil: [ self name ]
]

{ #category : 'automations' }
AgentTool class >> runAutomatedAction [
	"Services must opt into scheduled use explicitly. Most tools need
	arguments from a widget or fact, so a vague inherited default would hide
	too much intent."
	self error: self name
		, ' has no automated action; add a class-side #runAutomatedAction for safe zero-argument scheduled work or call a specific capability method from a widget'
]

{ #category : 'context' }
AgentTool class >> contextListing [
	"Legacy human-readable rendering retained for local inspection and tests.
	The gateway uses AgentPromptContext's bounded JSON envelope instead."
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
