require "test_helper"

module Alembic
  module Flow
    class RunTest < ActiveSupport::TestCase
      test "going back removes the last answer along the path, not the last in list order" do
        diagnostic = Definition.create!(slug: "jump")
        diagnostic.definition_versions.create!(number: 1, definition: flowing({
          "slug" => "jump", "entry" => "a",
          "nodes" => [
            { "id" => "a", "type" => "question", "text" => "A", "options" => [ "x" ] },
            { "id" => "b", "type" => "question", "text" => "B", "options" => [ "x" ] },
            { "id" => "c", "type" => "question", "text" => "C", "options" => [ "x" ] }
          ],
          "edges" => [ { "from" => "a", "to" => "c" }, { "from" => "c", "to" => "b" } ]
        }))
        diagnostic.publish_version(diagnostic.definition_versions.first)
        response = Run.start(diagnostic)
        response.update!(recorded: { a: "x", c: "x", b: "x" })

        response.discard_last

        assert_equal({ a: "x", c: "x" }, response.reload.recorded)
      end

      test "pins to the diagnostic's current definition version when started" do
        diagnostic = Definition.create!(slug: "demo")
        version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(version)

        response = Run.start(diagnostic)

        assert_equal version, response.definition_version
      end

      test "pins to the newer version once that version is published" do
        diagnostic = Definition.create!(slug: "demo")
        diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(diagnostic.definition_versions.first)
        republished = diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "demo" })
        diagnostic.publish_version(republished)

        response = Run.start(diagnostic.reload)

        assert_equal republished, response.definition_version
      end

      test "leaves an earlier response pinned to the version it began on" do
        diagnostic = Definition.create!(slug: "demo")
        began_on = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(began_on)
        response = Run.start(diagnostic)

        diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "demo" })

        assert_equal began_on, response.reload.definition_version
      end

      test "takes an owner of any type the host application supplies" do
        diagnostic = Definition.create!(slug: "demo")
        version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(version)
        owner = Definition.create!(slug: "owning-record")

        response = diagnostic.runs.create!(definition_version: version, owner: owner)

        assert_equal owner, response.reload.owner
      end

      test "is valid with no owner at all" do
        diagnostic = Definition.create!(slug: "demo")
        version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(version)

        response = diagnostic.runs.build(definition_version: version, owner: nil)

        assert response.valid?
      end

      test "records an answer into its stored answers" do
        response = Run.start(diagnostic_with_a_version)

        response.record(:pick, "a")

        assert_equal({ pick: "a" }, response.recorded)
      end

      test "reads its answers back from the database with symbol keys" do
        response = Run.start(diagnostic_with_a_version)
        response.record(:pick, "a")

        assert_equal({ pick: "a" }, response.reload.recorded)
      end

      test "reads the steps of the flow it is pinned to" do
        run = Run.start(alembic_flows(:db_guide))

        assert_includes run.pinned_definition["nodes"].map { |node| node["id"] }, "pick"
      end

      test "discards the answer it last recorded" do
        response = Run.start(alembic_flows(:db_guide))
        response.record(:pick, "a")

        response.discard_last

        assert_empty response.reload.recorded
      end

      private

      def diagnostic_with_a_version
        Definition.create!(slug: "demo").tap do |diagnostic|
          version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
          diagnostic.publish_version(version)
        end
      end

      test "pins the summary version the diagnostic is on when it starts" do
        diagnostic = Definition.create!(slug: "demo")
        diagnostic.record_definition("slug" => "demo")
        diagnostic.publish
        diagnostic.summaries.record("outputs" => [])

        assert_equal diagnostic.summaries.current_version, Run.start(diagnostic).summary_version
      end

      test "starts without a summary version when the diagnostic has no summary" do
        diagnostic = Definition.create!(slug: "demo")
        diagnostic.record_definition("slug" => "demo")
        diagnostic.publish

        assert_nil Run.start(diagnostic).summary_version
      end

      test "keeps its pinned summary version when the diagnostic records a newer one" do
        diagnostic = Definition.create!(slug: "demo")
        diagnostic.record_definition("slug" => "demo")
        diagnostic.publish
        diagnostic.summaries.record("outputs" => [])
        response = Run.start(diagnostic)

        assert_no_changes -> { response.reload.summary_version_id } do
          diagnostic.summaries.record("outputs" => [ { "id" => "score" } ])
        end
      end

      test "stays on the summary it was pinned to when a newer one is recorded" do
        diagnostic = scored_diagnostic
        run = Run.start(diagnostic)
        diagnostic.summaries.record("outputs" => [ { "id" => "score", "type" => "tally" } ])

        assert_equal "weighted_sum", run.reload.pinned_summary["outputs"].first["type"]
      end

      test "stays on the flow it was pinned to when the weights change" do
        diagnostic = scored_diagnostic
        run = Run.start(diagnostic)
        diagnostic.record_definition(flowing("slug" => "scored", "entry" => "budget", "edges" => [],
          "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                         "options" => [ { "value" => "high", "weight" => 99 } ] } ]))

        assert_equal 5, run.reload.pinned_definition["nodes"].first["options"].first["weight"]
      end

      test "reads no summary when none was pinned" do
        diagnostic = Definition.create!(slug: "unscored")
        diagnostic.record_definition("slug" => "unscored")
        diagnostic.publish

        assert_empty Run.start(diagnostic).pinned_summary
      end

      def scored_diagnostic
        Definition.create!(slug: "scored").tap do |diagnostic|
          diagnostic.record_definition("slug" => "scored", "entry" => "budget", "edges" => [],
            "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                           "options" => [ { "value" => "high", "weight" => 5 } ] } ])
          diagnostic.summaries.record("outputs" => [ { "id" => "score", "type" => "weighted_sum" } ])
          diagnostic.publish
        end
      end

      test "a run starts on the live version" do
        diagnostic = Definition.create!(slug: "demo", document: { "slug" => "demo" })
        diagnostic.publish

        run = Run.start(diagnostic)

        assert_equal diagnostic.live_version, run.definition_version
      end

      def pinned
        diagnostic = Definition.create!(slug: "pinned")
        diagnostic.record_definition(flowing(
          "slug" => "pinned", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "question" => "A?",
                         "answers" => [ { "value" => "yes" } ] },
                       { "id" => "b", "type" => "question", "question" => "B?",
                         "answers" => [ { "value" => "yes" } ] },
                       { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "end" } ]))
        diagnostic.publish
        Run.start(diagnostic)
      end

      test "reads the flow it was pinned to" do
        assert_equal "pinned", pinned.pinned_definition["slug"]
      end

      test "waits at the first step nothing has been recorded for" do
        assert_equal "a", pinned.next_step({}).id
      end

      test "moves on once a step has been recorded" do
        assert_equal "b", pinned.next_step("a" => "yes").id
      end

      test "reports the steps walked so far" do
        assert_equal({ "a" => "yes" }, pinned.walked("a" => "yes"))
      end

      test "reads the summary it was pinned to" do
        diagnostic = Definition.create!(slug: "summarised")
        diagnostic.record_definition(flowing("slug" => "summarised", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "question" => "A?",
                         "answers" => [ { "value" => "yes" } ] }, { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "a", "to" => "end" } ]))
        diagnostic.publish
        diagnostic.summaries.record("outputs" => [ { "id" => "counted", "type" => "tally" } ])

        assert_equal "counted", Run.start(diagnostic).pinned_summary["outputs"].first["id"]
      end
    end
  end
end
