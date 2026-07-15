"
I deliberately fail while describing myself so catalog tests can verify that
one generated widget cannot prevent the remaining knowledge snapshot.
"
Class {
	#name : 'AgentKnowledgeCatalogFailureProbe',
	#superclass : 'AgentWidget',
	#category : 'AgentSmalltalk-UITests',
	#package : 'AgentSmalltalk-UITests'
}

{ #category : 'agent context' }
AgentKnowledgeCatalogFailureProbe >> describe [
	self error: 'intentional knowledge projection failure'
]
