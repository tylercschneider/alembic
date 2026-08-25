require "test_helper"

module Alembic
  class SavedSessionsTest < ActionDispatch::IntegrationTest
    def branching
      { "slug" => "saved", "entry" => "budget",
        "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                       "options" => [ { "value" => "low", "label" => "Modest" }, { "value" => "high", "label" => "Generous" } ] },
                     { "id" => "gate", "type" => "condition", "answer" => "budget", "equals" => "high" },
                     { "id" => "posh", "type" => "question", "text" => "Premium tier?", "options" => [ "gold" ] },
                     { "id" => "plain", "type" => "question", "text" => "Basic tier?", "options" => [ "bronze" ] } ],
        "edges" => [ { "from" => "budget", "to" => "gate" },
                     { "from" => "gate", "to" => "posh", "on" => "yes" },
                     { "from" => "gate", "to" => "plain", "on" => "no" } ] }
    end

    def saved
      @saved ||= Diagnostic.create!(slug: "saved").tap { |diagnostic| diagnostic.record_definition(branching) }
    end

    test "starting a saved session sends the visitor to its durable URL" do
      post alembic.diagnostic_responses_path(saved.slug)

      assert_redirected_to alembic.response_path(Response.last)
    end

    test "a saved session renders the step it is waiting on" do
      run = Response.start(saved)

      get alembic.response_path(run)

      assert_select "legend", text: /Budget\?/
    end

    test "answering a step stores the answer against it" do
      run = Response.start(saved)

      patch alembic.response_path(run), params: { answers: { budget: "high" } }

      assert_equal({ budget: "high" }, run.reload.answers)
    end

    test "a saved session submits its answers back to itself" do
      run = Response.start(saved)

      get alembic.response_path(run)

      assert_select "form[action=?]", alembic.response_path(run)
    end

    test "an answer sends the visitor down the branch it selects" do
      run = Response.start(saved)

      patch alembic.response_path(run), params: { answers: { budget: "high" } }
      get alembic.response_path(run)

      assert_select "legend", text: /Premium tier\?/
    end

    test "going back removes the last answer along the walked path" do
      run = Response.start(saved)
      run.record_answer(:budget, "high")

      patch alembic.response_path(run), params: { back: "1" }

      assert_empty run.reload.answers
    end

    test "returning resumes at the step still waiting" do
      run = Response.start(saved)
      run.record_answer(:budget, "low")

      get alembic.response_path(run)

      assert_select "legend", text: /Basic tier\?/
    end

    test "a completed saved session lists what was said" do
      run = Response.start(saved)
      run.record_answer(:budget, "low")
      run.record_answer(:plain, "bronze")

      get alembic.response_path(run)

      assert_select "[data-answer=?]", "budget"
    end

    test "a session started before an edit still serves the version it began on" do
      run = Response.start(saved)
      saved.record_definition(branching.merge(
        "nodes" => branching["nodes"].map { |node| node["id"] == "budget" ? node.merge("text" => "Changed") : node }))

      get alembic.response_path(run)

      assert_select "legend", text: /Budget\?/
    end

    test "the intro offers to start a saved session" do
      get alembic.diagnostic_path(saved.slug)

      assert_select "form[action=?]", alembic.diagnostic_responses_path(saved.slug)
    end
  end
end
