"
I am the spatial canvas: a singleton wrapping a Bloc space on which AgentWidgets live.
Headless (no space open) I still hold widgets on a detached content element so the
code-generation loop can be exercised without a display.
"
Class {
	#name : 'AgentCanvas',
	#superclass : 'Object',
	#instVars : [
		'space',
		'content'
	],
	#classInstVars : [
		'current'
	],
	#category : 'AgentSmalltalk-UI',
	#package : 'AgentSmalltalk-UI'
}

{ #category : 'accessing' }
AgentCanvas class >> current [
	^ current ifNil: [ current := self new ]
]

{ #category : 'accessing' }
AgentCanvas class >> isOpen [
	^ current notNil and: [ current isOpen ]
]

{ #category : 'opening' }
AgentCanvas class >> open [
	^ self current open
]

{ #category : 'accessing' }
AgentCanvas class >> reset [
	current := nil
]

{ #category : 'testing' }
AgentCanvas >> isOpen [
	^ space notNil
]

{ #category : 'accessing' }
AgentCanvas >> space [
	^ space
]

{ #category : 'private' }
AgentCanvas >> ensureContent [
	content ifNil: [
		content := BlElement new.
		content background: (Color fromHexString: 'F4F1E8').
		content constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ] ].
	^ content
]

{ #category : 'opening' }
AgentCanvas >> open [
	space ifNotNil: [ ^ self ].
	self ensureContent.
	space := BlSpace new.
	space title: 'Agent Canvas'.
	space extent: 1280 @ 840.
	space root addChild: content.
	space root addEventHandlerOn: BlKeyDownEvent do: [ :evt |
		(evt key = KeyboardKey enter and: [ evt modifiers isCmd or: [ evt modifiers isCtrl ] ])
			ifTrue: [ AgentSpotlight openOn: self ] ].
	space show
]

{ #category : 'widgets' }
AgentCanvas >> addWidget: aWidget [
	self ensureContent.
	space
		ifNil: [ content addChild: aWidget ]
		ifNotNil: [ space enqueueTask: (BlTaskAction new action: [ content addChild: aWidget ]) ]
]

{ #category : 'widgets' }
AgentCanvas >> widgets [
	content ifNil: [ ^ #() ].
	^ content children asArray select: [ :c | c isKindOf: AgentWidget ]
]

{ #category : 'agent context' }
AgentCanvas >> contextDescription [
	^ String streamContents: [ :s |
		self widgets
			ifEmpty: [ s << '(the canvas is empty)' ]
			ifNotEmpty: [ :ws |
				ws do: [ :w |
					s << '- ' << w class name << ' at ' << w position printString
						<< ' — ' << w describe.
					s cr ] ] ]
]
