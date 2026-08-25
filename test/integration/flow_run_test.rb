require "test_helper"

module Alembic
  class FlowRunTest < ActionDispatch::IntegrationTest
    def flowed
      @flowed ||= Diagnostic.create!(slug: "flowed").tap do |diagnostic|
        diagnostic.record_definition(
          "slug" => "flowed", "entry" => "budget",
          "nodes" => [ { "id" => "budget", "type" => "question", "text" => "What is your budget?", "tag" => "money",
                         "options" => [ { "value" => "low", "label" => "Modest", "weight" => 1 },
                                        { "value" => "high", "label" => "Generous", "weight" => 5 } ] },
                       { "id" => "gate", "type" => "condition", "answer" => "budget", "equals" => "high" },
                       { "id" => "posh", "type" => "question", "text" => "Which premium tier?",
                         "options" => [ { "value" => "a", "weight" => 3 } ] },
                       { "id" => "plain", "type" => "question", "text" => "Which basic tier?",
                         "options" => [ { "value" => "b", "weight" => 1 } ] } ],
          "edges" => [ { "from" => "budget", "to" => "gate" },
                       { "from" => "gate", "to" => "posh", "on" => "yes" },
                       { "from" => "gate", "to" => "plain", "on" => "no" } ]
        )
        diagnostic.publish
      end
    end

    def summarised
      flowed.tap do |diagnostic|
        diagnostic.record_summary(
          "outputs" => [
            { "id" => "score", "type" => "weighted_sum", "label" => "Your score" },
            { "id" => "band", "type" => "band", "label" => "Where that puts you", "of" => "score",
              "bands" => [ { "ceiling" => 4, "name" => "Modest" }, { "name" => "Generous" } ] },
            { "id" => "areas", "type" => "grouped", "label" => "By area" },
            { "id" => "answered", "type" => "tally", "label" => "Steps answered" }
          ]
        )
      end
    end

    test "a finished run shows what its summary makes of it" do
      get alembic.diagnostic_step_path(summarised.slug), params: { answers: { budget: "high", posh: "a" } }

      assert_select "[data-output=?]", "score", text: /8/
    end

    test "a finished run names the band its score falls in" do
      get alembic.diagnostic_step_path(summarised.slug), params: { answers: { budget: "high", posh: "a" } }

      assert_select "[data-output=?]", "band", text: /Generous/
    end

    test "an answer stranded on an abandoned branch does not count toward the score" do
      get alembic.diagnostic_step_path(summarised.slug), params: { answers: { budget: "low", posh: "a", plain: "b" } }

      assert_select "[data-output=?]", "score", text: /2/
    end

    test "a finished run reports a share for each area it touched" do
      get alembic.diagnostic_step_path(summarised.slug), params: { answers: { budget: "high", posh: "a" } }

      assert_select "[data-output=?]", "areas", text: /money/
    end

    test "a finished run counts the steps it answered" do
      get alembic.diagnostic_step_path(summarised.slug), params: { answers: { budget: "high", posh: "a" } }

      assert_select "[data-output=?]", "answered", text: /2/
    end

    test "a diagnostic with no summary still shows what was said" do
      get alembic.diagnostic_step_path(flowed.slug), params: { answers: { budget: "low", plain: "b" } }

      assert_select "[data-answer=?]", "budget"
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

    test "a visitor runs the published version, not what the author is editing" do
      diagnostic = flowed
      diagnostic.publish
      diagnostic.update!(document: { "slug" => diagnostic.slug, "entry" => "gone", "nodes" => [], "edges" => [] })

      get alembic.diagnostic_step_path(diagnostic.slug)

      assert_select "legend", text: /What is your budget\?/
    end

    test "a visitor keeps running the published version after a newer one is cut" do
      diagnostic = flowed
      diagnostic.publish
      diagnostic.update!(document: { "slug" => diagnostic.slug, "entry" => "later",
        "nodes" => [ { "id" => "later", "type" => "question", "question" => "Something else?" } ], "edges" => [] })
      diagnostic.cut_version

      get alembic.diagnostic_step_path(diagnostic.slug)

      assert_select "legend", text: /What is your budget\?/
    end
  end
end
