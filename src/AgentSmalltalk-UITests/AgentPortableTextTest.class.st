Class {
	#name : 'AgentPortableTextTest',
	#superclass : 'TestCase',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'tests' }
AgentPortableTextTest >> testGeneratedTextAcceptsLanguageAndMeasurementCharacters [
	"Ordinary Unicode language text, accents and measurement symbols such as the
	degree sign render in the default font, so they must stay compilable."
	self shouldnt: [
		AgentPortableTextTestProbe compile:
			'title ^ ''São Paulo 18°C''' ] raise: Error
]

{ #category : 'tests' }
AgentPortableTextTest >> testMigrationStripsUnrenderableMaterialIcon [
	"A widget left over from the reverted icon experiment carries a Material
	ToImage whose BlSvgPath glyph aborts the canvas render. The update migration
	must strip it while keeping the widget."
	| widget icon hasSvg |
	hasSvg := [ :el | | found |
		found := false.
		el allChildrenBreadthFirstDo: [ :e |
			e geometry class name = #BlSvgPath ifTrue: [ found := true ] ].
		found ].
	widget := AgentPortableTextTestProbe new.
	icon := ToMaterialDesignIconProvider iconNamed: #filled_wbsunny ifAbsent: [ nil ].
	self assert: icon notNil.
	icon extent: 20 asPoint.
	widget addChild: icon.
	self assert: (hasSvg value: widget).
	widget removeUnrenderableIconElements.
	self deny: (hasSvg value: widget).
	self deny: (widget children includes: icon)
]

{ #category : 'tests' }
AgentPortableTextTest >> testGeneratedTextRejectsPictographs [
	"Emoji and pictographs cannot be drawn by the canvas backend and abort the
	whole render, so the compile guard must reject them before they enter the image."
	self
		should: [
			AgentPortableTextTestProbe compile:
				'title ^ ''☀ Weather''' ]
		raise: Error
]
