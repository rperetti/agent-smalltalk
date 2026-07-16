"
Clean-image contract for the deliberately small UI runtime.  Keep this focused
on the controls AgentSmalltalk promises to generated widgets and on upstream
packages which must not enter ordinary builds.
"
Class {
	#name : 'AgentDependencyLoadTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'tests' }
AgentDependencyLoadTest >> testAdvertisedToploControlsAreAvailable [
	#(ToBeeTheme ToAlbum ToLabel ToButton ToTextField ToCheckbox ToProgressBar)
		do: [ :globalName |
			self
				assert: (Smalltalk globals includesKey: globalName)
				description: globalName asString , ' is part of the advertised widget vocabulary' ].
	self assert: ToBeeTheme new notNil.
	self assert: ToAlbum new notNil.
	self assert: ToLabel new notNil.
	self assert: ToButton new notNil.
	self assert: ToTextField new notNil.
	self assert: ToCheckbox new notNil.
	self assert: ToProgressBar new notNil
]

{ #category : 'tests' }
AgentDependencyLoadTest >> testAdvertisedToploControlSelectorsAreAvailable [
	self assert: (ToLabel canUnderstand: #text:).
	self assert: (ToButton canUnderstand: #labelText:).
	self assert: (ToButton canUnderstand: #clickAction:).
	self assert: (ToTextField canUnderstand: #placeholderText:).
	self assert: (ToTextField canUnderstand: #text).
	self assert: (ToCheckbox canUnderstand: #labelText:).
	self assert: (ToCheckbox canUnderstand: #checkAction:).
	self assert: (ToCheckbox canUnderstand: #isChecked).
	self assert: (ToProgressBar canUnderstand: #valueInPercentage:).
	self assert: (ToAlbum canUnderstand: #placeholderText:).
	self assert: (ToAlbum canUnderstand: #text).
	self assert: (ToAlbum canUnderstand: #useScrollbar:)
]

{ #category : 'tests' }
AgentDependencyLoadTest >> testDefaultRuntimeExcludesUpstreamDevelopmentPackages [
	#(
		'Alexandrie-Base-Tests'
		'Alexandrie-FreeType-Tests'
		'Alexandrie-Cairo-Tests'
		'Alexandrie-CairoFreetype-Tests'
		'Alexandrie-Blur-Tests'
		'Alexandrie-FontManager-Tests'
		'Alexandrie-Harfbuzz-Tests'
		'Alexandrie-Canvas-Tests'
		'Alexandrie-NewTools'
		'Alexandrie-NewTools-Tests'
		'Bloc-Animation-Tests'
		'Bloc-Display-Tests'
		'Bloc-Scripter'
		'Bloc-Tests'
		'Bloc-Examples'
		'Bloc-Demo'
		'Bloc-DevTool'
		'Bloc-UnitedTests'
		'Album-Tests'
		'Album-Examples'
		'Album-Alexandrie'
		'Toplo-Tests'
		'Toplo-Demo'
		'Toplo-Examples'
		'Toplo-IDE'
		'Toplo-Incubator'
		'Toplo-Theme-Examples'
		'Toplo-Theme-Bee-Tests'
		'Toplo-Widget-Album-Tests'
		'Toplo-Widget-Button-Tests'
		'Toplo-Widget-List-Tests')
		do: [ :packageName |
			self
				assert: (PackageOrganizer default packageNamed: packageName ifAbsent: [ nil ]) isNil
				description: packageName , ' belongs only in an explicit upstream-development image' ]
]

{ #category : 'tests' }
AgentDependencyLoadTest >> testProductionRuntimeContainsTheSelectedClosure [
	#(
		'BlocHost-Morphic'
		'Bloc-FocusFinder'
		'Album'
		'Toplo'
		'Toplo-Theme'
		'Toplo-Theme-Bee'
		'Toplo-Widget-Album'
		'Toplo-Widget-Button'
		'Toplo-Widget-Circular'
		'Toplo-Widget-InnerWindow'
		'Toplo-Widget-Image'
		'Toplo-Widget-List'
		'Toplo-Widget-Pane'
		'Toplo-Widget-ProgressBar'
		'AgentSmalltalk-UICompatibility')
		do: [ :packageName |
			self
			assert: (PackageOrganizer default packageNamed: packageName ifAbsent: [ nil ]) notNil
			description: packageName , ' is required by the production UI closure' ]
]

{ #category : 'tests' }
AgentDependencyLoadTest >> testUnsupportedAlbumHooksFailExplicitly [
	self should: [ BlLazyElement new in: [ :element | element ] ] raise: Error.
	self should: [ TBlDevScripterTarget new onChildFromMessage: #editor ] raise: Error
]

{ #category : 'tests' }
AgentDependencyLoadTest >> testUpdaterReloadsTheProductionCompatibilityPackage [
	self assert: (AgentUpdater packageNames includes: 'AgentSmalltalk-UICompatibility')
]
