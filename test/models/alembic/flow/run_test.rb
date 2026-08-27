require "test_helper"

module Alembic
  module Flow
    class RunTest < ActiveSupport::TestCase
      test "going back removes the last answer along the path, not the last in list order" do
        diagnostic = Diagnostic.create!(slug: "jump")
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
        response = Flow::Run.start(diagnostic)
        response.update!(answers: { a: "x", c: "x", b: "x" })

        response.discard_last_answer

        assert_equal({ a: "x", c: "x" }, response.reload.answers)
      end

      test "pins to the diagnostic's current definition version when started" do
        diagnostic = Diagnostic.create!(slug: "demo")
        version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(version)

        response = Flow::Run.start(diagnostic)

        assert_equal version, response.definition_version
      end

      test "pins to the newer version once that version is published" do
        diagnostic = Diagnostic.create!(slug: "demo")
        diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(diagnostic.definition_versions.first)
        republished = diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "demo" })
        diagnostic.publish_version(republished)

        response = Flow::Run.start(diagnostic.reload)

        assert_equal republished, response.definition_version
      end

      test "leaves an earlier response pinned to the version it began on" do
        diagnostic = Diagnostic.create!(slug: "demo")
        began_on = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(began_on)
        response = Flow::Run.start(diagnostic)

        diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "demo" })

        assert_equal began_on, response.reload.definition_version
      end

      test "takes an owner of any type the host application supplies" do
        diagnostic = Diagnostic.create!(slug: "demo")
        version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(version)
        owner = Diagnostic.create!(slug: "owning-record")

        response = diagnostic.runs.create!(definition_version: version, owner: owner)

        assert_equal owner, response.reload.owner
      end

      test "is valid with no owner at all" do
        diagnostic = Diagnostic.create!(slug: "demo")
        version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        diagnostic.publish_version(version)

        response = diagnostic.runs.build(definition_version: version, owner: nil)

        assert response.valid?
      end

      test "records an answer into its stored answers" do
        response = Flow::Run.start(diagnostic_with_a_version)

        response.record_answer(:pick, "a")

        assert_equal({ pick: "a" }, response.answers)
      end

      test "reads its answers back from the database with symbol keys" do
        response = Flow::Run.start(diagnostic_with_a_version)
        response.record_answer(:pick, "a")

        assert_equal({ pick: "a" }, response.reload.answers)
      end

      test "builds its guide from the definition it is pinned to" do
        response = Flow::Run.start(alembic_diagnostics(:db_guide))

        assert_includes response.guide.questions.map(&:id), :pick
      end

      test "discards the answer it last recorded" do
        response = Flow::Run.start(alembic_diagnostics(:db_guide))
        response.record_answer(:pick, "a")

        response.discard_last_answer

        assert_empty response.reload.answers
      end

      private

      def diagnostic_with_a_version
        Diagnostic.create!(slug: "demo").tap do |diagnostic|
          version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
          diagnostic.publish_version(version)
        end
      end

      test "pins the summary version the diagnostic is on when it starts" do
        diagnostic = Diagnostic.create!(slug: "demo")
        diagnostic.record_definition("slug" => "demo")
        diagnostic.publish
        diagnostic.record_summary("outputs" => [])

        assert_equal diagnostic.current_summary_version, Flow::Run.start(diagnostic).summary_version
      end

      test "starts without a summary version when the diagnostic has no summary" do
        diagnostic = Diagnostic.create!(slug: "demo")
        diagnostic.record_definition("slug" => "demo")
        diagnostic.publish

        assert_nil Flow::Run.start(diagnostic).summary_version
      end

      test "keeps its pinned summary version when the diagnostic records a newer one" do
        diagnostic = Diagnostic.create!(slug: "demo")
        diagnostic.record_definition("slug" => "demo")
        diagnostic.publish
        diagnostic.record_summary("outputs" => [])
        response = Flow::Run.start(diagnostic)

        assert_no_changes -> { response.reload.summary_version_id } do
          diagnostic.record_summary("outputs" => [ { "id" => "score" } ])
        end
      end

      test "summarises from its pinned summary version rather than the diagnostic's newest" do
        diagnostic = scored_diagnostic
        response = Flow::Run.start(diagnostic)
        diagnostic.record_summary("outputs" => [ { "id" => "score", "type" => "tally" } ])

        assert_equal 5, response.reload.summary_of("budget" => "high").first.value
      end

      test "summarises from its pinned flow version when option weights change" do
        diagnostic = scored_diagnostic
        response = Flow::Run.start(diagnostic)
        diagnostic.record_definition(flowing("slug" => "scored", "entry" => "budget", "edges" => [],
          "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                         "options" => [ { "value" => "high", "weight" => 99 } ] } ]))

        assert_equal 5, response.reload.summary_of("budget" => "high").first.value
      end

      test "produces no outputs when its diagnostic has no summary" do
        diagnostic = Diagnostic.create!(slug: "unscored")
        diagnostic.record_definition("slug" => "unscored")
        diagnostic.publish

        assert_empty Flow::Run.start(diagnostic).summary_of({})
      end

      def scored_diagnostic
        Diagnostic.create!(slug: "scored").tap do |diagnostic|
          diagnostic.record_definition("slug" => "scored", "entry" => "budget", "edges" => [],
            "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                           "options" => [ { "value" => "high", "weight" => 5 } ] } ])
          diagnostic.record_summary("outputs" => [ { "id" => "score", "type" => "weighted_sum" } ])
          diagnostic.publish
        end
      end

      test "a run starts on the live version" do
        diagnostic = Diagnostic.create!(slug: "demo", document: { "slug" => "demo" })
        diagnostic.publish

        run = Flow::Run.start(diagnostic)

        assert_equal diagnostic.live_version, run.definition_version
      end

      def pinned
        diagnostic = Diagnostic.create!(slug: "pinned")
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
        diagnostic = Diagnostic.create!(slug: "summarised")
        diagnostic.record_definition(flowing("slug" => "summarised", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "question" => "A?",
                         "answers" => [ { "value" => "yes" } ] }, { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "a", "to" => "end" } ]))
        diagnostic.publish
        diagnostic.record_summary("outputs" => [ { "id" => "counted", "type" => "tally" } ])

        assert_equal "counted", Run.start(diagnostic).pinned_summary["outputs"].first["id"]
      end
    end
  end
end
