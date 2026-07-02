# Project Specification: Living Agentic Environment (Smalltalk-Inspired OS) 

## Product Vision & Core Philosophy 

The goal is to build a symbiotic operating system and living agentic environment where code and knowledge are mixed together. Moving away from a static "chatbot" paradigm, the user and AI collaborate within a persistent, continuously evolving workspace.

Core Tenets 

* **The Persistent "Image"**: The system never forgets context. Code, memory, user preferences, and tasks are saved in a unified, continuously evolving graph (the Smalltalk "image").


* **Object Uniformity (Knowledge = Code)**: There is no fundamental difference between passive data and active capabilities. A piece of knowledge (a note) and a tool (an executable script) are both addressable objects.


* **Live Coding & Debugging**: The system modifies itself while running. The agent can inspect, change, and compile code mid-execution without restarting.



## System Architecture 

The prototype relies on a hybrid architecture, combining the object-oriented purity of Smalltalk with the reasoning power of modern cloud-based frontier models.

* **The Environment (Native OS)**: A native Smalltalk image built on Pharo. Everything in the environment is a live object.


* **The Brain (AI Engine)**: A cloud-based frontier Large Language Model (e.g., Anthropic Claude or OpenAI).


* **The Bridge (HTTP Gateway)**: A dedicated Smalltalk class that manages the network bridge, handles API keys, formats JSON payloads, and manages network latency.


* **The Code Extractor**: A Smalltalk method that parses the LLM's HTTP response, strips away conversational text or Markdown, and isolates raw, compilable Smalltalk code.



## The Execution Loop 

The AI does not live locally, so the execution loop must elegantly translate live memory into a text context window and turn text responses back into live objects.

1. **The Prompt**: The user interacts with the system to request a tool or action.


2. **Context Mapping (Serialization)**: The environment packages the user's request alongside a lightweight, text-based map of the current available classes and objects.


3. **Inference**: The gateway sends the payload to the external LLM via HTTP REST API.


4. **Live Compilation**: The Smalltalk image receives raw Smalltalk code and evaluates it in real-time without restarting. If building a tool, it instantiates the new class immediately.



## User Interface: The Infinite Spatial Canvas 

The environment discards the traditional chat window and file folder structures in favor of an infinite, multiplayer spatial canvas.

* **UI Framework**: Built using Bloc, Pharo’s modern, low-level UI infrastructure. Bloc treats UI elements (BlElement) as nodes in an optimized scene graph, supporting vector graphics, smooth animations, and zooming.


* **Spotlight Summoning**: Instead of a chat sidebar, users hit a global shortcut (e.g., Cmd+Space) to open a floating text bar. Typing a command causes the agent to generate code, and a fully functioning custom widget instantly pops into existence under the cursor.


* **Direct Manipulation**: Users can visually drag and resize UI elements. If a user drags a new input box onto an LLM-generated widget, the underlying Smalltalk code automatically rewrites itself to match the visual change.


* **Spatial Context (Proximity = Meaning)**: The X/Y coordinates of widgets dictate context. Users can draw a lasso around a specific cluster of widgets; the system then serializes only those highlighted objects to send to the LLM, effectively managing the context window.



## Autonomous Canvas Management 

The agent acts as an "invisible spatial gardener," managing the digital geography while the user focuses on tasks.

* **Camera Panning & Wormholes**: If the user asks for a distant widget, the agent calculates its coordinates and fluidly pans the camera to center on it. Alternatively, it can "teleport" or temporarily duplicate the widget to the user's current view.


* **Semantic Clustering**: In the background, the agent reads the context of scattered nodes and applies physics-based attraction (like a force-directed graph) to naturally group related items.


* **Breadcrumb Trails**: When the agent guides the user to a distant cluster, it leaves a visual string (spline) connecting the previous location to the new one to map mental connections.



## Primary Use Cases & Examples 

* **The Persistent Assistant**: A user tells the agent, "I'm working on the tax report." Three days later, they say, "add this invoice to it." The agent immediately knows what the context is and executes the necessary script to process the invoice.


* **Conversational Debugging**: The agent fails to scrape a website because the layout changed. It enters a "debugger" state and shows the code. The user says, "look for the div named sidebar-content," and the agent updates its tool mid-execution and finishes the task.


* **PDF to Twitter Script**: A user drops a PDF onto the canvas. The agent extracts concepts as clickable nodes. The user highlights a node and types, "Write a script to track mentions of this concept on Twitter". The agent attaches the running script to the node.


* **Data that Works**: The user drops an Excel sheet of expenses onto the canvas and says, "make this data trackable". The agent writes code that binds a dynamic chart directly to the file object, turning it into an application.


* **Visual Programming**: The user draws a visual line connecting an "Email Inbox" node to a "To-Do List" widget. The agent writes the Smalltalk script bridging them, automatically popping up "urgent" emails as checkboxes.



## System Prompt Blueprint 

The system prompt sent in every HTTP payload is the sole mechanism for instructing the frontier model on how to operate the OS. It must enforce the following: 

1. **Acknowledge the Environment**: Explicitly inform the model it is generating code for a live Smalltalk image (Pharo) and that its output will be evaluated immediately.


2. **Output Raw Code**: Instruct the model to output only syntactically valid Smalltalk code, avoiding any Markdown formatting, explanations, or conversational filler.


3. **Assume Object Uniformity**: Remind the model that everything is an object that sends and receives messages. It must interact with data by calling methods on objects, not by querying external relational databases.
