# Consuming the flow interface

Alembic's flow layer is a general-purpose, step-typed graph engine. Nothing in
it knows what a "question" is — diagnostics are just the first consumer. A host
application teaches it new step types and drives the walk itself.

This document describes the interface a consuming application talks to. It is
written against the code as it stands, so that the layer can be extracted into
its own gem without the contract changing.

## The three artifacts

A flow separates what to ask, what was said, and what it means. Each is a
distinct artifact, and a host may implement any one without the others.

| Artifact | What it is | Who owns it |
|---|---|---|
| **Template** | the flow document — typed nodes joined by edges | the builder writes it |
| **Run** | `state` — a hash of node id to recorded value | the host's runner |
| **Summary** | outputs computed from a finished run | the summary layer |

The template is data. The runner is a loop the host writes. The summary is a
separate registry that reads a finished run.

## 1. The flow document

A flow is plain JSON. Three keys:

```json
{
  "entry": "budget",
  "nodes": [
    { "id": "budget", "type": "question", "question": "What is your budget?",
      "category": "money",
      "answers": [ { "value": "low",  "label": "Modest",   "weight": 1 },
                   { "value": "high", "label": "Generous", "weight": 5 } ] },
    { "id": "rich", "type": "condition", "answer": "budget", "equals": "high" },
    { "id": "posh", "type": "question", "question": "Which premium tier?" }
  ],
  "edges": [
    { "from": "budget", "to": "rich" },
    { "from": "rich", "to": "posh", "on": "yes" }
  ]
}
```

- `entry` — the id of the node the walk starts from.
- `nodes` — each needs `id` and `type`. **Every other key is that step type's
  config**, and is handed to the type's hooks untouched.
- `edges` — `from` and `to` are node ids. `on` names an output port, and is
  omitted for step types that have a single unnamed output.

Wrap it in `Flow::Document`:

```ruby
document = Alembic::Flow::Document.new(JSON.parse(raw))
```

`Document` is immutable — every edit returns a new `Document` (see §5). It does
not care where the JSON came from; Alembic stores it in an append-only
`alembic_definition_versions` table, but a host can keep it in a file, a
column, or an API response.

## 2. Defining step types

A step type is a class that includes `Alembic::Flow::Step`. It is registered once
and referenced by `type` in the document.

```ruby
module MyApp
  module Steps
    class Agent
      include Alembic::Flow::Step

      step_name "Agent"

      setting :prompt, type: :string
      setting :model, type: :string

      names_by :prompt
      awaits_input
    end
  end
end
```

The step type's id comes from the class name — `MyApp::Steps::Agent` registers as
`:agent` — and `register` is provided for you.

Register at boot, inside `to_prepare` so the types survive a code reload:

```ruby
# config/initializers/flow.rb
Rails.application.config.to_prepare do
  MyApp::Steps::Agent.register
end
```

Registration is deliberately explicit: there is no hook that registers a class as
a side effect of defining it, because that interacts badly with reloading and
eager loading.

### Behaviour is a method

A step type that decides where the walk goes next defines `route`, which gives
its helpers somewhere private to live:

```ruby
module MyApp
  module Steps
    class Gate
      include Alembic::Flow::Step

      setting :of, type: :string
      outputs :approved, :rejected

      def route(node, state)
        approved?(state[node.config["of"]]) ? :approved : :rejected
      end

      private

      def approved?(result)
        result.to_h["ok"]
      end
    end
  end
end
```

### Without the module

`Alembic::Flow::StepType.define` is the primitive underneath, and remains
available for a host that would rather not include a module into its class:

```ruby
MyApp::AGENT = Alembic::Flow::StepType.define(:agent) do
  step_name "Agent"
  setting :prompt, type: :string
end

Alembic::Flow.registry.register(MyApp::AGENT)
```

### The declaration DSL

| Method | Effect |
|---|---|
| `step_name "Agent"` | the name shown in the builder palette. Defaults to the id |
| `setting :name, type: :string` | declares a config key and how the builder should edit it |
| `outputs :pass, :fail` | named output ports. Omit for a single unnamed output |
| `awaits_input` | this step stops the walk until the host records a value for it |
| `names_by :prompt` | which setting titles the node on the canvas |
| `route { \|node, state\| }` | returns which port to leave by |
| `displays_by { \|node\| }` | what the runner hands back for this step. Omit and it hands back the node |
| `drawn_by "steps/tiles"` | the template that draws this step. Omit and the overall one draws it |
| `process { \|node, state\| }` | what this step does when the runner reaches it. Its return value is recorded against the step |

### Setting types

`:string` `:integer` `:float` `:boolean` `:select` `:multi_select` `:list`

Anything else raises `Flow::UnknownFieldType`. These describe the *editing
affordance* the builder offers; the engine never interprets a setting's value.

`:integer` and `:float` differ only in the editor they produce — a whole-number
step versus any decimal. **Declaring either does not yet coerce what is stored**:
a submitted value is written through as the form supplied it, so an `:integer`
setting can still hold `"1"` rather than `1`. Transforms that read a number
should coerce defensively until that is fixed.

`:list` is a repeating group and must say what one entry holds, using a block:

```ruby
setting :options, type: :list do
  setting :value,  type: :string
  setting :label,  type: :string
  setting :weight, type: :integer
end
```

A block always means the settings each entry has, and nothing else. A `:list`
declared without one raises `Flow::UnknownFieldType`.

`:select` and `:multi_select` must say what they offer. A `:select` stores one of
them, a `:multi_select` an array:

```ruby
setting :model,    type: :select,       options: %w[opus sonnet haiku]
setting :channels, type: :multi_select, options: %w[email sms push], limit: 2
```

These are the **author** choosing at build time from a set the step type fixes. A
`:list` is the author creating entries. A question step's answers are a `:list`
even though a visitor later picks one of them — that is the step type's run-time
behaviour, not its configuration.

### Bounding a value

`limit:` caps how many entries a `:list` or `:multi_select` accepts. `check:`
takes anything callable, returning a message when the value is unacceptable and
`nil` when it is fine:

```ruby
setting :channels, type: :multi_select, options: %w[email sms push], limit: 2,
  check: ->(chosen) { "Channels needs at least one" if chosen.blank? }
```

`StepType#objections(config)` returns the messages for a configuration. Alembic's
builder calls it when a step is configured and refuses the edit if any come back,
so a rejected value never reaches the document.

This is how scoring data rides along on a step: authored in the builder, stored
on the node, invisible to whoever walks the flow, and read later by the summary.

### Routing

A step with `outputs` must decide which port it leaves by:

```ruby
class Gate
  include Alembic::Flow::Step

  outputs :pass, :fail

  setting :answer, type: :previous_step

  def route(node, state)
    state[node.config["answer"]] == node.config["expects"] ? :pass : :fail
  end
end
```

`route` returns a port name; the walk follows the edge whose `on` matches. A
step with no `outputs` follows its first outgoing edge. If `route` returns a
port with no matching edge, the walk ends there.

### Requirements

A `previous_step` setting holds the id of a step this one depends on, and that
is the whole declaration — nothing else names the dependency.

Three things follow from it. The builder offers the steps that come before this
one rather than a box to type an id into. The validator refuses a node that
leaves it blank. And the validator enforces the dependency as **graph
dominance**: it is met only if removing the named node makes this node
unreachable, so a step that merely happens to sit upstream on *one* branch is a
violation.

## 3. Driving a run

`Flow::Digest` is the whole runtime interface. It is a set of pure functions
over `(document, state)` — it holds no run state of its own.

```ruby
digest = Alembic::Flow::Digest.new(document)
```

**`state` is a hash keyed by node id as a String.** Values are whatever the host
records; the engine never inspects them except through a step type's hooks.

| Method | Returns |
|---|---|
| `entry` | the entry `Node` |
| `step(id)` | one `Node`, or nil |
| `steps` | every `Node` in the document |
| `requirements(id)` | the ids that node depends on |
| `next_step(state)` | the next node awaiting input, or `nil` when finished |
| `state_on_path(state)` | `state` reduced to what is still on the walked path |

### The runner

`Flow::Runner` is that walk with the loop already written. A host builds one
from a document and asks it what to show next.

```ruby
runner = Alembic::Flow::Runner.new(document)

runner.next_step(state)      # the step to show now, or nil when finished
runner.state_on_path(state)  # state reduced to the path walked
runner.steps_on_path(state)  # the steps that path reached
runner.step("budget")        # one step by id
runner.steps                 # every step in the document
```

`next_step` hands back whatever the step's own type declares it displays, and
the `Node` itself when it declares nothing. That declaration is `displays_by`,
and it is how a host puts its own shape on a run without writing a walk:

```ruby
class Question
  include Alembic::Flow::Step

  awaits_input

  displays_by { |node| Asked.new(id: node.id.to_sym, text: asked(node.config)) }
end
```

### A step that acts

A step type declaring `process` does something when the runner reaches it rather
than waiting for input. The walk stops at it the same way it stops at a step
awaiting input, and `Flow::Runner#run` is what runs it:

```ruby
class Deliver
  include Alembic::Flow::Step

  setting :message, type: :string
  setting :to, type: :previous_step

  def process(node, state)
    Mailer.deliver(node.config["message"], to: state[node.config["to"]])
  end
end
```

```ruby
runner.run(progress)         # runs every process reached, recording each result
runner.next_step(state)      # the next step awaiting input
```

What a process returns is recorded against its own step id, exactly as an answer
is, so a later condition reads it through `state` like any other value.

**`run` is the only call that has effects, and it is called once per request.**
`next_step`, `state_on_path` and `steps_on_path` are called several times while
one page is built, so a process running inside the walk would run several times.
Keep effects in `run`.

A process result is recorded through the same strategy an answer is, so a flow
keeping nothing carries it forward in the request rather than running it again.

### Drawing a step

`displays_by` says what a step hands back; `drawn_by` says what draws it. A
template is picked from the first of these that names one:

1. the step type's own `drawn_by`
2. the overall template, `Flow.draws_with("steps/panel")`
3. the one the flow system ships, which draws a step offering options

The template is rendered with the display as `step`, inside the form the host's
controller already set up, so it draws the step and nothing around it:

```erb
<%# app/views/steps/_tiles.html.erb %>
<fieldset>
  <legend><%= step.text %></legend>

  <% step.choices.each do |choice| %>
    <%= radio_button_tag "answers[#{step.id}]", choice.value %>
    <%= label_tag "answers[#{step.id}]_#{choice.value}", choice.label %>
  <% end %>
</fieldset>
```

The shipped template reads `text`, `id` and `choices`, and each choice's
`value`, `label` and `hint`. A step type whose display answers those is drawn by
it with no template of its own; one that does not name its own.

### What a run keeps

The walk is the same wherever state lives, so where it lives is a strategy
rather than a second code path. `Flow::Progress` holds it, and a flow names
which one it uses:

| Strategy | State lives in | Buys | Costs |
|---|---|---|---|
| `unsaved` | what the host hands in | no storage at all | nothing survives the request |
| `each_step` | a `Flow::Run`, written per answer | resuming from a durable url | a write per step |
| `on_finish` | a `Flow::Run`, written once at the end | nothing stored for an abandoned run | no resuming |

```ruby
progress = Alembic::Flow::Progress.for(flow, run: run, answers: answers)

progress.recorded            # the state so far
progress.record(id, value)   # take one answer
progress.discard_last        # step back
progress.finish(state)       # the run, or nil when the flow keeps none
progress.definition          # what this run walks — pinned for a kept run
```

A run handed in wins over the flow's setting, so a run already under way
keeps behaving as it started.

A host wanting the loop itself still has it:

```ruby
state = {}

while (step = digest.next_step(state))
  state[step.id] = perform(step.type, step.config)
end

finished = digest.state_on_path(state)
```

`next_step` walks from `entry`, evaluating conditions against `state` as it
goes, and stops at the first node whose type `awaits_input` and which has no
recorded value. Nodes that don't await input — conditions, and anything else
purely structural — are traversed silently.

### Why `state_on_path` matters

If someone answers a question, then changes an earlier answer so a different
branch is taken, the first answer is still sitting in `state` but is no longer
on the path. `state_on_path` drops it. **Always summarise the path-correct
state**, not the raw hash, or abandoned answers will score.

The walk is also cycle-safe: it tracks visited ids and stops rather than
looping forever on a document that points backwards.

## 4. Validating

```ruby
violations = Alembic::Flow::Validator.new(document).violations
```

Each `Violation` carries `node`, `problem`, and sometimes `detail`.

| `problem` | Meaning |
|---|---|
| `:missing_entry` | `entry` names a node that isn't there |
| `:missing_edge_target` / `:missing_edge_source` | an edge points at an unknown node |
| `:duplicate_id` | two nodes share an id |
| `:unreachable` | a node no walk from `entry` can arrive at |
| `:unmet_requirement` | a `previous_step` id does not dominate this node |

Three levels, narrowest first: `malformations` (broken references — the
document is not usable), `structural_violations` (adds unreachable nodes), and
`violations` (adds unmet requirements).

Every mutating `Document` method runs `malformations` and raises
`Flow::InvalidEdit` rather than returning a corrupt document. Reachability and
requirements are *not* enforced on edit — a half-built flow is allowed to be
temporarily broken while someone is still building it.

## 5. Editing the document

For hosts building their own editor. All return a new `Document`:

| Method | Effect |
|---|---|
| `add(node)` | append a node, no edges |
| `insert(node, on: [from, to], leaving: port)` | splice into an existing edge |
| `connect(from:, to:, on: nil)` | add an edge |
| `disconnect(from:, to:)` | drop an edge |
| `rewire(from:, to:, target:)` | repoint an edge's destination |
| `move(id, on:, leaving:)` | remove then re-insert elsewhere |
| `configure(id, config)` | replace a node's config, keeping `id` and `type` |
| `remove(id)` | drop a node, bridging its incoming edges to its outgoing ones |

`remove` deliberately heals the graph: every incoming edge is reconnected to
every outgoing one, so deleting a step from the middle does not sever the flow.

When inserting a node that has named ports, pass `leaving:` — otherwise its new
outgoing edge has no port and the walk cannot leave it.

## 6. Summarising

The summary layer mirrors the step registry, and is deliberately separate: a
host can walk a flow without ever summarising, or summarise a run recorded
elsewhere.

An output type is a pure transform:

```ruby
Alembic::Summary.output(:weighted_sum) do
  label "Score"
  compute { |config, run, so_far| ... }
end
```

- `config` — the output's own entry from the summary document
- `run` — a `Summary::Run`, holding `state` and the step definitions
- `so_far` — outputs already computed this pass, keyed by id, so an output can
  build on an earlier one

Outputs are computed **in document order**, which is what lets `band` read the
score that `weighted_sum` just produced.

`Summary::Run` gives a transform both halves of the picture:

```ruby
run.state          # => { "budget" => "high" }   what was answered
run.step("budget") # => the node's config hash   what was asked
```

The summary document is a list of outputs:

```json
{ "outputs": [
    { "id": "score", "type": "weighted_sum", "label": "Your score" },
    { "id": "band",  "type": "band", "of": "score",
      "bands": [ { "ceiling": 10, "name": "Getting started" }, { "name": "Strong" } ] } ] }
```

Run it:

```ruby
run     = Alembic::Summary::Run.new(state: finished, steps: nodes_by_id)
results = Alembic::Summary::Report.new(summary_document).results(run)

results.first.label  # => "Your score"
results.first.value  # => 5
```

Each result is a `Summary::Result` — `id`, `label`, `value`. `label` falls back
to the output type's own label when the document doesn't override it. An
unknown type raises `Summary::UnknownOutputType`.

## 7. Deciding who may see a flow

A flow is closed until the host says otherwise. Publishing a version decides
*what* a visitor would run; it does not decide *whether* anyone may run it.

Name a method on your base controller and the engine asks it before every
visitor request:

```ruby
# config/initializers/alembic.rb
Alembic.base_controller = "ApplicationController"
Alembic.visitor_authorization_method = :alembic_visitor_permitted?
```

```ruby
class ApplicationController < ActionController::Base
  def alembic_visitor_permitted?(diagnostic)
    current_user&.entitled_to?(diagnostic.slug)
  end
end
```

The engine only wants the yes or no. Whatever decides it — a passphrase, an
account entitlement, a purchase record — stays yours.

**Configure nothing and every flow is closed.** There is no open default and no
setting that opens everything at once.

### The refusals

The gate raises one of three errors, so you can tell the cases apart:

| Error | Meaning |
|---|---|
| `Alembic::NotPublished` | The flow has no live version. |
| `Alembic::NotPermitted` | It is live, but not for this visitor, or the diagnostic is inactive. |
| `Alembic::Withdrawn` | The version this run was part-way through was withdrawn. |

Configure nothing and all three render a plain `404`. That is deliberate: a closed
flow is indistinguishable from one that does not exist, so a slug cannot be
probed to learn what is there, and the engine has nowhere sensible to send
someone it knows nothing about.

To answer a refusal your own way — a redirect to a login, a paywall, a
passphrase prompt — name a method and the engine hands it the refusal:

```ruby
# config/initializers/alembic.rb
Alembic.refusal_method = :alembic_refused
```

```ruby
class ApplicationController < ActionController::Base
  def alembic_refused(refusal)
    return head :not_found if refusal.is_a?(Alembic::NotPublished)

    redirect_to login_path
  end
end
```

**Do not reach for `rescue_from` here.** The engine's controllers inherit from
your base controller, so a handler you register there is registered first and
the engine's own handler shadows it. The named method is the seam that works.

### Previewing what visitors cannot reach

An admin reaches a preview through the builder, never through the visitor
route:

```
/alembic/manage/diagnostics/:id/preview
```

It runs the published flow the way a visitor would and is authenticated as the
rest of the builder is, so the visitor gate has no bypass in it. A flow with
nothing published has nothing to preview.

## 8. Version statuses and availability

Two separate things decide whether someone can run a flow: the status of a
version, and the availability of the diagnostic itself.

### A version's status

Every version a host creates carries one of five statuses.

| Status | New runs start | Runs in flight | Publishable | Can return to |
|---|---|---|---|---|
| `draft` | no | — | yes | yes |
| `live` | yes | continue | — | yes |
| `superseded` | no | continue | yes, again | yes |
| `retired` | no | continue | no | no |
| `withdrawn` | no | **stopped** | no | no |

Retired and withdrawn are the pair to choose between. Retired stops new people
arriving and lets anyone part-way through finish. Withdrawn stops them too.

Publishing makes a version `live` and marks the previously live one
`superseded`. Exactly one version can be `live`, enforced by a unique index
rather than by convention.

A version row is never destroyed by a status change, so a finished run stays
exactly re-derivable no matter what happened to its version afterwards.

```ruby
diagnostic.publish                          # current version becomes live
diagnostic.retire_version(some_version)     # no new runs, in-flight continue
diagnostic.withdraw_version(some_version)   # in-flight stopped too
```

Publishing or returning to a retired or withdrawn version raises
`Alembic::OutOfService`.

### A diagnostic's availability

Separately, a diagnostic is `active`, `hidden` or `inactive`.

| Status | Reachable by link | Runs in flight | In `Diagnostic.listable` |
|---|---|---|---|
| `active` | yes | continue | yes |
| `hidden` | yes | continue | no |
| `inactive` | no | **stopped** | no |

Alembic has no public list of its own, so `hidden` only means the host leaves
it out of whatever list the host builds:

```ruby
Alembic::Diagnostic.listable
```

An inactive diagnostic raises `Alembic::NotPermitted`, and a withdrawn version
raises `Alembic::Withdrawn`, both answered by the host the same way the other
refusals are.

## 9. What ships built in

Two step types, both registered by the engine:

- **`question`** — `question`, `answers` (a list of `value`/`label`/`weight`
  entries), `category`. Awaits input.
- **`condition`** — `answer`, and either `equals` or `in` (a list of `value`
  entries). Ports `yes`/`no`. `in` wins when it has entries.

Six output types:

| Type | Config | Value |
|---|---|---|
| `weighted_sum` | — | sum of the chosen options' weights |
| `percentage` | — | that sum as a share of the maximum reachable on the path taken |
| `grouped` | `by` (defaults to the step's `category`) | `{ category => percentage }` for each category answered |
| `lowest` | `of`, `count` (default 1) | the weakest tags from a `grouped` output |
| `tally` | `tag`, `by` (defaults to the step's `category`) | how many steps were answered, optionally for one category |
| `band` | `of`, `bands` | the first band whose `ceiling` the value falls under |

`bands` are sorted by `ceiling`; a band with no `ceiling` is the catch-all.

None of these are privileged — they register through the same public call a
host would use, and a host can add its own or ignore them entirely.

## 10. Known gaps

Documented so nobody builds against something that isn't there:

- **`single_output?` is unused** — `Digest` infers the same thing from whether
  `route` returns a port.

## 11. A non-diagnostic example

Nothing above is question-shaped. The same engine orchestrating agent work:

```ruby
class Agent
  include Alembic::Flow::Step

  step_name "Agent"
  setting :prompt, type: :string
  setting :model, type: :string
  names_by :prompt
  awaits_input
end

class Review
  include Alembic::Flow::Step

  step_name "Review gate"
  setting :of, type: :previous_step
  outputs :approved, :rejected

  def route(node, state)
    state[node.config["of"]][:ok] ? :approved : :rejected
  end
end
```

```json
{ "entry": "draft",
  "nodes": [
    { "id": "draft",  "type": "agent",  "prompt": "Draft the release notes" },
    { "id": "check",  "type": "review", "of": "draft" },
    { "id": "polish", "type": "agent",  "prompt": "Tighten the wording" },
    { "id": "redo",   "type": "agent",  "prompt": "Start over, more concise" } ],
  "edges": [
    { "from": "draft", "to": "check" },
    { "from": "check", "to": "polish", "on": "approved" },
    { "from": "check", "to": "redo",   "on": "rejected" } ] }
```

```ruby
state = {}
while (step = digest.next_step(state))
  state[step.id] = Agents.run(step.config["prompt"], model: step.config["model"])
end
```

The builder, the document format, the walk, the validator, and the summary are
all unchanged. Only the step types differ — which is the whole point of the
split.
