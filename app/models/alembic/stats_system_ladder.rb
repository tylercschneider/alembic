module Alembic
  module StatsSystemLadder
    SLUG = "stats-system-ladder"
    Q = Guide::Question
    O = Guide::Option
    N = Guide::Node
    B = Guide::BuildStep

    def self.build
      Guide.new(
        slug: SLUG,
        questions: questions,
        resolver: StatsLadderPlacement.new,
        kicker: "Diagnose · Place · Build",
        headline: "Where does your system actually need to be?",
        blurb: "Most stats feel wrong because they're built one tier too low — or one tier too high. Answer a few questions, find your rung on the ladder, then see what it costs, why it works, the pain that tells you to climb, and how to build it.",
        start_label: "Start the quiz →",
        tiers: tiers,
        levels: levels,
        warnings: warnings
      )
    end

    def self.warnings
      {
        insight_pairing: "Insight-grade — you can keep collection light and fast; approximate is fine here.",
        money_pairing: "Money-grade on a durable level — your numbers will be exact and recoverable. Good pairing.",
        sourcing_floor: "Event sourcing needs a durable floor — Level 3 minimum. Lossy collection can't be the source of truth.",
        money_vs_lossy: "Money-grade events can't live on the lossy telemetry sink — it silently drops data you'd need to reconcile. Route them through the durable outbox (Level 3), and keep anonymous telemetry as a separate sink that stitches to your business events at conversion."
      }
    end

    def self.levels
      { l12: level_in_process, l3: level_outbox, l4: level_broker, l0: level_telemetry }
    end

    def self.level_in_process
      N.new(
        id: :l12, name: "In-process · sync / async", tagline: "Emit in code, or enqueue a job.",
        complexity: "trivial", setup: "a method call / an ActiveJob", maintenance: "low",
        captures: "Events handled inside your app, synchronously or in a background job.",
        why: "Cheapest possible event handling. Right when losing one is genuinely fine (directional, insight-grade metrics).",
        pains: "Events lost on crash or job failure, silently. No dedup, no dead-letter, can't bind the event to the business transaction.",
        avoid: "Naive retries with no idempotency.",
        avoid_pain: "Duplicate or lost events and no way to know what you missed.",
        build_steps: [
          B.new(title: "Sync (Level 1)", code: "subscribers.each { |s| s.handle(event) }  # in the request"),
          B.new(title: "Async (Level 2)", code: "HandleEventJob.perform_later(event)  # survives the request, not a crash")
        ]
      )
    end

    def self.level_outbox
      N.new(
        id: :l3, name: "Outbox · durable", tagline: "Committed in the same transaction as the change.",
        complexity: "medium", setup: "outbox table · relay/publisher · idempotency keys", maintenance: "monitor outbox · dead-letter · retention pruning",
        captures: "Events that cannot be lost and are atomic with the business write.",
        why: "Solves the dual-write problem: the event and the state change commit together or not at all. The floor for money-grade and for event sourcing.",
        pains: "Real machinery to run and monitor. The outbox is a queue — mutable, pruned — so it is not your permanent record (project to an events table for that).",
        avoid: "Dual-write — write the DB, then publish separately.",
        avoid_pain: "The classic failure: DB commits but publish fails (or the reverse), and state and events silently diverge.",
        build_steps: [
          B.new(title: "Write event in the same txn as the change", code: "transaction do\n  deal.update!(state: :won)\n  Outbox.create!(event_id: SecureRandom.uuid, name: \"deal_closed\", payload: {...})\nend"),
          B.new(title: "A relay ships committed rows, then marks them", code: "# background loop\nOutbox.unpublished.find_each { |o| deliver(o); o.update!(published_at: Time.now) }")
        ]
      )
    end

    def self.level_broker
      N.new(
        id: :l4, name: "Broker · cross-service", tagline: "Events must reach another service.",
        complexity: "high (ops)", setup: "Kafka/broker · consumers · schema registry · partitioning", maintenance: "broker ops · consumer lag · ordering · replay",
        captures: "Durable delivery to consumers outside your process.",
        why: "Decouples services through an event stream; supports replay and many independent consumers.",
        pains: "Operational weight: a broker to run, ordering and lag to reason about, schema evolution across teams.",
        avoid: "Services poll each other's databases or share one DB.",
        avoid_pain: "Tight coupling, brittle integrations, no replay — a distributed monolith.",
        build_steps: [
          B.new(title: "Outbox relays to the broker", code: "producer.produce(topic: \"deals\", key: deal_id, payload: event.to_json)")
        ]
      )
    end

    def self.level_telemetry
      N.new(
        id: :l0, name: "Telemetry sink · fire-and-forget", tagline: "High-volume anonymous signals (page views, clicks).",
        complexity: "medium", setup: "collector endpoint · batching · columnar sink · pre-aggregation", maintenance: "the ingest pipeline + columnar store",
        captures: "Pre-identity, high-frequency web signals feeding top-of-funnel marketing stats.",
        why: "Built for volume the outbox could never carry. Lossy by design — one page view is worthless, the aggregate is everything. Stitches to business events at lead capture.",
        pains: "A whole second store to operate. Never your system of record. Must not share the business-events table.",
        avoid: "Stuff page views into the same events/outbox table.",
        avoid_pain: "Outbox and DB overwhelmed; billions of near-worthless rows drown your business events; retention becomes a nightmare.",
        build_steps: [
          B.new(title: "Thin collector: accept, validate, enqueue, 202", code: "# POST /collect\ndef collect\n  validate!(params)        # against the shared schema\n  Buffer.push(params)      # fire-and-forget\n  head :accepted           # 202, no inline work\nend"),
          B.new(title: "Batch-flush to the columnar store, pre-aggregate", code: "# worker drains Buffer -> ClickHouse/lake in batches\n# pre-roll sessions, landing-page CVR, A/B variant lift on ingest"),
          B.new(title: "Stitch to a business event at conversion", code: "# form_submitted -> lead_created, freezing utm/variant/anonymous_id\nemit :lead_created, source_id:, variant_id:, anonymous_id:")
        ]
      )
    end

    def self.tiers
      { 1 => tier_one, 2 => tier_two, 3 => tier_three, 4 => tier_four, 5 => tier_five }
    end

    def self.tier_one
      N.new(
        id: 1, name: "Live query on current state", tagline: "Compute it on demand from rows as they exist now.",
        complexity: "trivial", setup: "DB + the right index", maintenance: "none",
        captures: "The current value, exact to the second. \"How many contacts,\" \"open jobs,\" \"current pipeline.\"",
        why: "Always correct, zero infrastructure, nothing to invalidate. The right answer far more often than people think.",
        pains: "No history — the table only knows now. Deletes and edits erase the past. Cannot answer \"how many last March.\"",
        avoid: "Raise timeouts, throw hardware at the DB, sprinkle ad-hoc view caching.",
        avoid_pain: "Mystery slow pages and a count query that quietly becomes the app bottleneck.",
        build_steps: [
          B.new(title: "Index what you filter on", code: "# migration\nadd_index :contacts, :status"),
          B.new(title: "Just ask the database", code: "Contact.where(status: :active).count\nJob.where(state: :open).sum(:value_cents)"),
          B.new(title: "That is the whole tier", code: "# no job, no table, no cache. climb only when a trigger below fires.")
        ]
      )
    end

    def self.tier_two
      N.new(
        id: 2, name: "Cached current state", tagline: "The same value, memoized so the read is cheap.",
        complexity: "low", setup: "counter_cache / Redis / matview", maintenance: "keeping the cache correct (invalidation)",
        captures: "Same questions as Tier 1, at scale or on hot paths.",
        why: "Fast reads. counter_cache is the clean form — the framework keeps the number current as rows come and go, so reads are free.",
        pains: "Still no history. New risk: a cache that drifts if invalidation is wrong. Freshness becomes a choice, not a guarantee.",
        avoid: "Cache it manually in fifty places with no single invalidation path.",
        avoid_pain: "Stale numbers nobody trusts and bugs you can never reproduce.",
        build_steps: [
          B.new(title: "counter_cache — the clean version", code: "class Job < ApplicationRecord\n  belongs_to :contact, counter_cache: true\nend\n# migration: add_column :contacts, :jobs_count, :integer, default: 0\n# backfill: Contact.find_each { |c| Contact.reset_counters(c.id, :jobs) }"),
          B.new(title: "Or a Redis counter for cross-cutting totals", code: "# on write\n$redis.incr(\"open_jobs\")   # decr on close\n# on read\n$redis.get(\"open_jobs\").to_i"),
          B.new(title: "Or a materialized view on a refresh schedule", code: "CREATE MATERIALIZED VIEW pipeline_now AS ...;\n-- refresh nightly / on demand\nREFRESH MATERIALIZED VIEW CONCURRENTLY pipeline_now;")
        ]
      )
    end

    def self.tier_three
      N.new(
        id: 3, name: "Periodic snapshot", tagline: "A scheduled job writes the current value to a history table.",
        complexity: "low–med", setup: "a scheduled job + a metrics table", maintenance: "the cron job; backfilling gaps when a run fails",
        captures: "Trends of a level over time: \"contacts at each month-end,\" \"pipeline over the year.\"",
        why: "First tier that creates history the current-state tables can't reconstruct. Deleting a contact never touches yesterday's snapshot.",
        pains: "Granularity is fixed by cadence — daily means no hourly, ever. Captures levels, lies about flow: 3 created + 2 deleted shows as +1, and the 3 and 2 are gone.",
        avoid: "Keep soft-deleted rows forever to reconstruct history; track numbers by hand in a spreadsheet.",
        avoid_pain: "Bloated tables, \"deleted\" data leaking into live queries, and a spreadsheet that becomes the real (always-stale) source of truth.",
        build_steps: [
          B.new(title: "A history table keyed by date", code: "create_table :daily_metrics do |t|\n  t.date :as_of, null: false\n  t.integer :contacts, :open_jobs\n  t.bigint :pipeline_cents\nend\nadd_index :daily_metrics, :as_of, unique: true"),
          B.new(title: "A nightly job that samples current state", code: "class SnapshotJob\n  def perform\n    DailyMetric.upsert({\n      as_of: Date.today,\n      contacts: Contact.count,\n      open_jobs: Job.open.count,\n      pipeline_cents: Job.open.sum(:value_cents)\n    }, unique_by: :as_of)\n  end\nend"),
          B.new(title: "Schedule it (sidekiq-cron / whenever)", code: "# every day at 00:05\nSnapshotJob.perform_at(\"5 0 * * *\")")
        ]
      )
    end

    def self.tier_four
      N.new(
        id: 4, name: "Event log + rollups", tagline: "Record every occurrence as an immutable event; aggregate from it.",
        complexity: "high — the big jump", setup: "event defs · emission at each change · events table · rollups · registry", maintenance: "rollup correctness + reconciliation · event versioning",
        captures: "Flow and causality exactly — every thing that happened, in order, with its values frozen. Rates, conversion, time-between-states, drift-proof attribution.",
        why: "The churn problem disappears (you see the 3 and the 2). Attribution survives later edits because the value was copied into the event, not pointed at. Any new breakdown is just a re-aggregation.",
        pains: "You only get the dimensions you snapshotted into the payload. Records what happened; does not rebuild an entity's arbitrary past state. Most moving parts so far.",
        avoid: "Compute rates from same-period snapshots (this-month closes ÷ this-month leads); store the daily ratio instead of its two counts; derive \"events\" by diffing state at end of day.",
        avoid_pain: "Metrics that invert under volume, average-of-averages errors, and a corrupt event log with fabricated timestamps — the \"feels wrong because it IS wrong\" problem.",
        build_steps: [
          B.new(title: "Define the event (schema-first)", code: "class DealClosed < EventDefinition\n  required_payload :lead_id, :salesperson_id, :source_id\n  required_payload :amount_cents\n  # occurred_at (spine) = when it happened\nend"),
          B.new(title: "Emit at the moment of the change — freeze the values", code: "def close_deal!(deal)\n  deal.update!(state: :won)\n  emit :deal_closed,\n    lead_id: deal.lead_id, salesperson_id: deal.rep_id,\n    source_id: deal.lead.source_id,   # frozen NOW, survives later edits\n    amount_cents: deal.total_cents\nend"),
          B.new(title: "Project into a permanent, queryable events table", code: "create_table :events do |t|\n  t.uuid :event_id; t.string :name\n  t.datetime :occurred_at\n  t.bigint :source_id, :salesperson_id  # promoted = filterable\n  t.bigint :amount_cents\n  t.jsonb :payload\nend\nadd_index :events, :event_id, unique: true\nadd_index :events, [:name, :occurred_at]"),
          B.new(title: "Roll up by recomputation (idempotent, auditable)", code: "INSERT INTO sales_rollups (period, source_id, deals, revenue_cents)\nSELECT date_trunc('month', occurred_at), source_id,\n  count(*), sum(amount_cents)\nFROM events WHERE name = 'deal_closed'\nGROUP BY 1, 2\nON CONFLICT (period, source_id) DO UPDATE SET ...;"),
          B.new(title: "Reconcile — the recompute is the auditor", code: "# nightly: rebuild from events, diff vs incremental rollup.\n# any mismatch = a caught bug. unique event_id stops double-counting.")
        ]
      )
    end

    def self.tier_five
      N.new(
        id: 5, name: "Event sourcing", tagline: "Events ARE the record; state is a projection you replay.",
        complexity: "high — model inverts", setup: "event store · replay · snapshotting", maintenance: "event versioning/upcasting forever · replay performance",
        captures: "Everything Tier 4 does, plus arbitrary past state and full audit replay — questions you never anticipated.",
        why: "One source of truth. Reconstruct any moment. Fix a projection and re-derive it cleanly. Strongest possible audit position.",
        pains: "Heaviest to build and reason about. Overkill for most data. Replay and old-event versioning become permanent concerns. Resist it unless you truly need reconstruction or regulatory replay.",
        avoid: "Bolt on an audit_log; add history columns ad hoc; keep a changes table.",
        avoid_pain: "Partial history covering only what you anticipated, audit gaps exactly where you didn't log, two sources of truth that disagree.",
        build_steps: [
          B.new(title: "Events are the only writes", code: "# never UPDATE state. append facts.\nstore.append(deal_id, :deal_closed, amount_cents: 1_850_000)"),
          B.new(title: "State is folded from the stream", code: "def rebuild(deal_id)\n  store.events_for(deal_id).reduce(Deal.new) do |deal, event|\n    deal.apply(event)   # pure function: (state, event) -> state\n  end\nend"),
          B.new(title: "Snapshot for replay speed; query as-of any date", code: "# \"what did this look like on 2026-03-31?\"\nstore.events_for(deal_id, before: Date.new(2026, 3, 31)).reduce(...)")
        ]
      )
    end

    def self.questions
      [ need_question, read_question, loss_question, origin_question ]
    end

    def self.origin_question
      Q.new(
        id: :origin,
        text: "Where do the events come from / who needs them?",
        condition: ->(answers) { [ "rates", "audit" ].include?(answers[:need]) },
        options: [
          O.new("app", "My own app, handled in-process", "the common case"),
          O.new("anon", "High-volume anonymous web signals", "page views, clicks, A/B — marketing"),
          O.new("svc", "Other services need to consume them", "cross-service integration")
        ]
      )
    end

    def self.loss_question
      Q.new(
        id: :loss,
        text: "If a single underlying event were silently lost, what is the impact?",
        condition: ->(answers) { answers[:need] == "rates" },
        options: [
          O.new("insight", "Negligible — it is directional", "a glance, a trend, a vanity funnel"),
          O.new("money", "It would throw off money, commissions, or a real decision", "must be exact and reconcilable")
        ]
      )
    end

    def self.read_question
      Q.new(
        id: :read,
        text: "How heavily is this number read versus how often the data changes?",
        condition: ->(answers) { answers[:need] == "now" },
        options: [
          O.new("light", "Read occasionally — fine to compute live", "no performance pressure"),
          O.new("hot", "Read constantly / on hot pages / under load", "it shows up in latency or DB load")
        ]
      )
    end

    def self.need_question
      Q.new(
        id: :need,
        text: "What is the most advanced question you need to answer about this number?",
        options: [
          O.new("now", "Just its value right now", "how many contacts / open jobs / current pipeline"),
          O.new("trend", "How it has changed over time", "trends, vs last month, charts over months"),
          O.new("rates", "Rates, conversion, flow — or attribution that survives edits", "close rate, time-to-close, profit by source"),
          O.new("audit", "What any record looked like at an arbitrary past moment", "full audit, replay, \"what did we believe at time T\"")
        ]
      )
    end
  end
end
