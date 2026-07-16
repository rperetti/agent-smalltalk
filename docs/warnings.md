# Native loader warning policy

The native build and test paths fail on compiler and package warnings by
default. An active exception must have one ID here, one `AS_WARNING` line in
the native loader log, a severity assessment, and a concrete review trigger.
An unknown ID, a missing active ID, or a raw unresolved warning fails the gate.

Do not add an exception to make a warning disappear. First identify its source,
whether a supported production path can execute it, and whether it can affect
data or the integrity of the loaded image. Record the assessment before
committing the source change that produces the warning.

## Active exceptions

<!-- warning-policy: ASW-ALBUM-LEGACY-HOOKS -->

### ASW-ALBUM-LEGACY-HOOKS — Medium

Pinned Album includes two legacy definitions outside Agent Smalltalk's
production UI contract: an asynchronous adornment strategy that names absent
`BlLazyElement`, and Scripter extensions whose target lives in excluded
`Bloc-Scripter`. Agent Smalltalk uses neither path. The local compatibility
types make both paths fail explicitly, rather than leave an undeclared global
or load the Scripter developer stack.

The normal UI is unaffected. Calling either unsupported path fails that UI
operation. Fresh builds would otherwise emit unresolved compiler/package
warnings, and a future upstream class with either global name could change the
meaning of the local compatibility type. Review this exception whenever Album
or Bloc changes; remove it when Album offers a runtime package without these
definitions or Agent Smalltalk adopts a maintained source patch.

<!-- warning-policy: ASW-TOPLO-CYCLIC-BOOTSTRAP -->

### ASW-TOPLO-CYCLIC-BOOTSTRAP — Low after verification

The selected Toplo runtime packages contain a cyclic class graph. Their first
load creates temporary undeclared references before every class exists. The
loader then recompiles the complete selected graph with undeclared references
treated as fatal; no such association may survive into the image.

This is a bootstrap condition, not a supported runtime path. Treat a changed
cycle, a failed clean recompilation, or a warning outside this phase as a new
warning requiring assessment. Review the exception whenever the selected Toplo
closure changes.
