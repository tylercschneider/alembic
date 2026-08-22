require "test_helper"

module Alembic
  class SavedSessionsTest < ActionDispatch::IntegrationTest
    test "starting a saved session sends the visitor to its durable URL" do
      post alembic.diagnostic_responses_path("db-guide")

      assert_redirected_to alembic.response_path(Response.last)
    end

    test "a saved session renders the question it is waiting on" do
      response = Response.start(alembic_diagnostics(:db_guide))

      get alembic.response_path(response)

      assert_select "legend", text: /Pick one option/
    end

    test "answering a question in a saved session stores the answer on the response" do
      response = Response.start(alembic_diagnostics(:db_guide))

      patch alembic.response_path(response), params: { answers: { pick: "a" } }

      assert_equal({ pick: "a" }, response.reload.answers)
    end

    test "a saved session submits its answers back to itself" do
      response = Response.start(alembic_diagnostics(:db_guide))

      get alembic.response_path(response)

      assert_select "form[action=?]", alembic.response_path(response)
    end

    test "a completed saved session names the band its stored answers land in" do
      response = Response.start(scored_diagnostic)
      response.record_answer(:need, "yes")
      response.record_answer(:team, "no")

      get alembic.response_path(response)

      assert_select "h1", text: /Well instrumented/
    end

    test "going back a step in a saved session removes its last stored answer" do
      response = Response.start(scored_diagnostic)
      response.record_answer(:need, "yes")

      patch alembic.response_path(response), params: { back: "1" }

      assert_empty response.reload.answers
    end

    test "the intro offers to start a saved session" do
      get alembic.diagnostic_path("db-guide")

      assert_select "form[action=?]", alembic.diagnostic_responses_path("db-guide")
    end

    private

    def scored_diagnostic
      Diagnostic.create!(slug: "saved-scored", kind: "scored").tap do |diagnostic|
        diagnostic.record_definition(scored_definition)
      end
    end

    def scored_definition
      {
        "slug" => "saved-scored",
        "questions" => [
          { "id" => "need", "text" => "Need?", "options" => [ { "value" => "yes", "label" => "Yes", "weight" => 5 }, { "value" => "no", "label" => "No", "weight" => 0 } ] },
          { "id" => "team", "text" => "Team?", "options" => [ { "value" => "yes", "label" => "Yes", "weight" => 3 }, { "value" => "no", "label" => "No", "weight" => 0 } ] }
        ],
        "bands" => [ { "ceiling" => 4, "name" => "Flying blind" }, { "ceiling" => nil, "name" => "Well instrumented" } ]
      }
    end
  end
end
