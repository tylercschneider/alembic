require "test_helper"

module Alembic
  class ResponseTest < ActiveSupport::TestCase
    test "going back removes the last answer along the path, not the last in list order" do
      diagnostic = Diagnostic.create!(slug: "jump")
      diagnostic.definition_versions.create!(number: 1, definition: {
        "slug" => "jump", "entry" => "a",
        "nodes" => [
          { "id" => "a", "type" => "question", "text" => "A", "options" => [ "x" ] },
          { "id" => "b", "type" => "question", "text" => "B", "options" => [ "x" ] },
          { "id" => "c", "type" => "question", "text" => "C", "options" => [ "x" ] }
        ],
        "edges" => [ { "from" => "a", "to" => "c" }, { "from" => "c", "to" => "b" } ]
      })
      response = Response.start(diagnostic)
      response.update!(answers: { a: "x", c: "x", b: "x" })

      response.discard_last_answer

      assert_equal({ a: "x", c: "x" }, response.reload.answers)
    end

    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      response = diagnostic.responses.create!(definition_version: version)

      assert_equal diagnostic, response.diagnostic
    end

    test "pins to the diagnostic's current definition version when started" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      response = Response.start(diagnostic)

      assert_equal version, response.definition_version
    end

    test "pins to the newer version when started after a recompile" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      recompiled = diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "demo" })

      response = Response.start(diagnostic.reload)

      assert_equal recompiled, response.definition_version
    end

    test "leaves an earlier response pinned to the version it began on" do
      diagnostic = Diagnostic.create!(slug: "demo")
      began_on = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      response = Response.start(diagnostic)

      diagnostic.definition_versions.create!(number: 2, definition: { "slug" => "demo" })

      assert_equal began_on, response.reload.definition_version
    end

    test "takes an owner of any type the host application supplies" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      owner = Diagnostic.create!(slug: "owning-record")

      response = diagnostic.responses.create!(definition_version: version, owner: owner)

      assert_equal owner, response.reload.owner
    end

    test "is valid with no owner at all" do
      diagnostic = Diagnostic.create!(slug: "demo")
      version = diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      response = diagnostic.responses.build(definition_version: version, owner: nil)

      assert response.valid?
    end

    test "records an answer into its stored answers" do
      response = Response.start(diagnostic_with_a_version)

      response.record_answer(:pick, "a")

      assert_equal({ pick: "a" }, response.answers)
    end

    test "reads its answers back from the database with symbol keys" do
      response = Response.start(diagnostic_with_a_version)
      response.record_answer(:pick, "a")

      assert_equal({ pick: "a" }, response.reload.answers)
    end

    test "builds its guide from the definition it is pinned to" do
      response = Response.start(alembic_diagnostics(:db_guide))

      assert_equal :pick, response.guide.questions.first.id
    end

    test "discards the answer it last recorded" do
      response = Response.start(alembic_diagnostics(:db_guide))
      response.record_answer(:pick, "a")

      response.discard_last_answer

      assert_empty response.reload.answers
    end

    private

    def diagnostic_with_a_version
      Diagnostic.create!(slug: "demo").tap do |diagnostic|
        diagnostic.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      end
    end

    test "pins the summary version the diagnostic is on when it starts" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("slug" => "demo")
      diagnostic.record_summary("outputs" => [])

      assert_equal diagnostic.current_summary_version, Response.start(diagnostic).summary_version
    end

    test "starts without a summary version when the diagnostic has no summary" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("slug" => "demo")

      assert_nil Response.start(diagnostic).summary_version
    end

    test "keeps its pinned summary version when the diagnostic records a newer one" do
      diagnostic = Diagnostic.create!(slug: "demo")
      diagnostic.record_definition("slug" => "demo")
      diagnostic.record_summary("outputs" => [])
      response = Response.start(diagnostic)

      assert_no_changes -> { response.reload.summary_version_id } do
        diagnostic.record_summary("outputs" => [ { "id" => "score" } ])
      end
    end

    test "summarises from its pinned summary version rather than the diagnostic's newest" do
      diagnostic = scored_diagnostic
      response = Response.start(diagnostic)
      diagnostic.record_summary("outputs" => [ { "id" => "score", "type" => "tally" } ])

      assert_equal 5, response.reload.summary_of("budget" => "high").first.value
    end

    test "summarises from its pinned flow version when option weights change" do
      diagnostic = scored_diagnostic
      response = Response.start(diagnostic)
      diagnostic.record_definition("slug" => "scored", "entry" => "budget", "edges" => [],
        "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                       "options" => [ { "value" => "high", "weight" => 99 } ] } ])

      assert_equal 5, response.reload.summary_of("budget" => "high").first.value
    end

    test "produces no outputs when its diagnostic has no summary" do
      diagnostic = Diagnostic.create!(slug: "unscored")
      diagnostic.record_definition("slug" => "unscored")

      assert_empty Response.start(diagnostic).summary_of({})
    end

    def scored_diagnostic
      Diagnostic.create!(slug: "scored").tap do |diagnostic|
        diagnostic.record_definition("slug" => "scored", "entry" => "budget", "edges" => [],
          "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                         "options" => [ { "value" => "high", "weight" => 5 } ] } ])
        diagnostic.record_summary("outputs" => [ { "id" => "score", "type" => "weighted_sum" } ])
      end
    end
  end
end
