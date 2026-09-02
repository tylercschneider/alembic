# The flow vocabulary

Every word the flow layer uses, what it means, and where it lives. One name per
thing: where two words could mean the same thing, this file says which one is
used and the other is not used at all.

Read this before `consuming.md`, which assumes these words.

## The thing being built

**Flow** — the whole feature, and the module every part of it lives in.

**Definition** (`flow/definition.rb`) — the record for one flow. It holds the
slug, the title, the working document, and the versions and runs belonging to
it. The name is historical: a definition *is* a flow rather than the definition
of one.

**Document** (`flow/document.rb`) — a flow's shape as plain data, being a list
of nodes and a list of edges. It is immutable, so every edit returns a new one.

**Never called a template.** A template is the file that draws a step, and
nothing else.

**Node** (`flow/node.rb`) — one step in a document, carrying an `id`, a `type`
and a `config`. The config is every other key on it, handed to that step type's
declarations untouched.

**Edge** (`flow/edge.rb`) — a line from one node to another, carrying `from`,
`to` and `on`.

**Port** — the value in an edge's `on`, naming which exit of a step that edge
leaves by. A step with one way out uses no port.

**Entry** — the node a walk starts from. It is not stored anywhere; it is found
by asking each node's step type whether it begins the flow.

## What defines a kind of step

**Step type** (`flow/step_type.rb`) — the class behind a node's `type`. The
engine ships `question`, `condition`, `switch`, `start` and `terminal`, and a
host registers its own.

**Registry** (`flow/registry.rb`) — the map from a type name to its step type.
`Flow.registry` is the global one, filled when the engine boots. Every part of
the flow layer takes a registry rather than reaching for the global one, so a
host can hand it a different set.

**Declaration** (`flow/step_type/declaration.rb`) — the builder that gathers a
step type's declarations and produces it.

**Settings** (`flow/settings.rb`) — what a node of a given type may be
configured with, and whether a configuration is acceptable.

**Display** — what the runner hands back for a step, built by `displays_by`.
It is not the template and it is not the node.

**Template** — the file that draws a step, named by `drawn_by`. This is the only
meaning of the word.

The words a step type declares:

| Word | What it says |
|---|---|
| `step_name` | the name shown in the builder's palette |
| `setting` | one key this type accepts in a node's config, and what it holds |
| `output` | a named exit, which is to say a port |
| `awaits_input` | the walk stops here until a value is recorded against it |
| `process` | work to do when the walk reaches this step |
| `route` | which port to leave by |
| `displays_by` | what the runner hands back for this step |
| `drawn_by` | which template draws it |
| `names_by` | which setting titles it on the canvas |
| `begins_here` | it is where a flow starts |
| `ends_here` | it is where a flow ends |

A `previous_step` setting holds the id of an earlier step, and that one
declaration also makes the setting required and makes the validator enforce the
dependency.

## Running one

**State** — a hash of node id to recorded value, holding what has happened in a
run so far. The engine never inspects a value; only a step type's own
declarations do.

**Walk** — following edges from the entry, evaluating routes against state, and
stopping at the first step that needs something. A step needs something when it
awaits input, or when it has a process that has not run.

**Digest** (`flow/digest.rb`) — the walk. Pure functions over a document and a
state, holding nothing of its own and safe to call repeatedly.

**Runner** (`flow/runner.rb`) — the digest plus what a caller wants from it: the
next step as its own type displays it, the template that draws it, and running
any process the walk passes. `run` is the only call with effects.

**Run** (`flow/run.rb`) — the record of one person going through a flow. It
holds what they recorded, and pins the version and summary it began under so
neither changes underneath them.

**Progress** (`flow/progress.rb`) — where a run's state is kept. `Kept` for a
run stored against a record, `Loose` for one carried in the request.

**Persistence strategy** — which of those a flow uses, named on the flow
itself: `unsaved`, `each_step` or `on_finish`.

## Versions, checking and building

**Version** (`flow/version.rb`) — one saved copy of a document. **Live** is the
version visitors run.

**Edit history** (`flow/edit_history.rb`) — the undo and redo of the working
document, and the list of changes made since the last version.

**Validator** (`flow/validator.rb`) — refuses a document that cannot run.
**Violation** (`flow/violation.rb`) — one fault it found: a node, a problem, and
sometimes a detail.

**Canvas** (`flow/canvas.rb`) — everything the builder needs, drawn as JSON.
**Layout** (`flow/layout.rb`) — where the boxes sit on it.

**Summaries** (`flow/summaries.rb`) — outputs computed from a finished run.

**Admission** (`flow/admission.rb`) — whether someone may run a flow at all.

## Words this layer does not use

| Not used | Use instead |
|---|---|
| template, for a flow's nodes and edges | document |
| question | step, unless the `question` step type is meant |
| answer | the value recorded against a step |
| diagnostic | flow |
