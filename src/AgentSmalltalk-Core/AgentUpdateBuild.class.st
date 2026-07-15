"
I am replaced only in a staged update candidate. The committed source has no
build identity; update.sh writes the exact preflight manifest into its private
copy before that candidate is loaded.
"
Class {
	#name : 'AgentUpdateBuild',
	#superclass : 'Object',
	#category : 'AgentSmalltalk-Core',
	#package : 'AgentSmalltalk-Core'
}

{ #category : 'accessing' }
AgentUpdateBuild class >> manifest [
	^ nil
]
