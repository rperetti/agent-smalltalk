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
