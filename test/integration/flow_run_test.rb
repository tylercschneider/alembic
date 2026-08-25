require "test_helper"

module Alembic
  class FlowRunTest < ActionDispatch::IntegrationTest
    def flowed
      @flowed ||= Diagnostic.create!(slug: "flowed").tap do |diagnostic|
        diagnostic.record_definition(
          "slug" => "flowed", "entry" => "budget",
          "nodes" => [ { "id" => "budget", "type" => "question", "text" => "What is your budget?",
                         "options" => [ { "value" => "low", "label" => "Modest" }, { "value" => "high", "label" => "Generous" } ] },
                       { "id" => "gate", "type" => "condition", "answer" => "budget", "equals" => "high" },
                       { "id" => "posh", "type" => "question", "text" => "Which premium tier?", "options" => [ "a" ] },
                       { "id" => "plain", "type" => "question", "text" => "Which basic tier?", "options" => [ "b" ] } ],
          "edges" => [ { "from" => "budget", "to" => "gate" },
                       { "from" => "gate", "to" => "posh", "on" => "yes" },
                       { "from" => "gate", "to" => "plain", "on" => "no" } ]
        )
      end
    end

    test "a visitor can see the intro of a nodes and edges diagnostic" do
      get alembic.diagnostic_path(flowed.slug)

      assert_response :success
    end

    test "the intro links into the flow" do
      get alembic.diagnostic_path(flowed.slug)

      assert_select "a[href=?]", alembic.diagnostic_step_path(flowed.slug)
    end

    test "a visitor is asked the step the flow begins at" do
      get alembic.diagnostic_step_path(flowed.slug)

      assert_select "legend", text: /What is your budget\?/
    end

    test "a visitor is offered a labelled choice for each option" do
      get alembic.diagnostic_step_path(flowed.slug)

      assert_select "label", text: /Generous/
    end

    test "answering sends the visitor down the branch their answer selects" do
      get alembic.diagnostic_step_path(flowed.slug), params: { answers: { budget: "high" } }

      assert_select "legend", text: /Which premium tier\?/
    end

    test "the other answer sends them down the other branch" do
      get alembic.diagnostic_step_path(flowed.slug), params: { answers: { budget: "low" } }

      assert_select "legend", text: /Which basic tier\?/
    end

    test "a visitor reaching the end is told the run is complete" do
      get alembic.diagnostic_step_path(flowed.slug), params: { answers: { budget: "low", plain: "b" } }

      assert_response :success
    end

    test "a saved session walks the same flow" do
      response_record = Response.start(flowed)

      patch alembic.response_path(response_record), params: { answers: { budget: "high" } }
      get alembic.response_path(response_record)

      assert_select "legend", text: /Which premium tier\?/
    end

    test "a saved session records the answer against the step that asked it" do
      response_record = Response.start(flowed)

      patch alembic.response_path(response_record), params: { answers: { budget: "high" } }

      assert_equal({ budget: "high" }, response_record.reload.answers)
    end
  end
end
