# Ideas parking lot

Things we've deliberately deferred, so they don't evaporate. Each entry says
where it came from and why it's parked.

## Variables on the canvas

*From the phase 2 brainstorm (2026-07-03), sparked by fact keys like `#city`.*

A fact key is secretly a **global variable**: set it once, use it as input
anywhere on the canvas (`AgentKnowledge at: #city` — the lookup queries the
sticky widgets, so the canvas remains the single store). Widgets could bind
to variables at build time or hold live references so editing the sticky
re-parameterizes every widget wired to it.

The rabbit hole underneath (later / maybe never): local/temporary variables;
visually **wiring** a variable to a widget; scoping rules where a local
overrides a global for one widget or one region of canvas. This starts to be
a visual programming language — which is also where the original spec's
"draw a line from Email to To-Do" use case lives.

Parked because: phase 2 only needs keys as identity-for-updates. The variable
semantics deserve their own phase with the wiring UX thought through.

## Preferences and settings as scoped knowledge

*From the phase 2 brainstorm.*

"I like dark widgets" is knowledge *about how to build*, not about the world
— a preference. Preferences feel like **scoped variables**: scoped to a
widget class, to a region, or to the whole canvas. The deep end: the agent's
own instructions (crib-sheet fragments) becoming visible, editable objects on
the canvas — the system's behavior becomes direct-manipulable.

Parked because: needs the variables story first, and it changes how the crib
sheet is assembled per request.

## Promote a note to a fact

*From the answer-notes brainstorm (2026-07-03).*

A note sometimes turns out to contain something durable ("actually, keep
this"). Today the path is asking the agent to copy it into a fact; a direct
gesture (drag note onto the facts pile? a button?) would make the
ephemeral→durable transition a physical act, like deletion already is.
Parked because: needs so little that it can ride along whenever sticky
interactions next get touched.

## Theming the canvas and widgets

*From the phase 2 brainstorm.*

User-controlled look of the whole environment: canvas colors, widget default
style, dark mode. Toplo ships a theme system (`ToBeeTheme`, `ToBeeDarkTheme`,
style sheets) we already install — theming could start as "expose theme
choice" and grow into "the agent restyles widgets on request", which
connects back to preferences-as-knowledge.

Parked because: cosmetic until knowledge + variables give it something to
hang on (a `#theme` fact scoped to the canvas is the natural shape).
