require "test_helper"

module Alembic
  class DiagnosticsFlowTest < ActionDispatch::IntegrationTest
    test "the intro renders the diagnostic title" do
      get alembic.diagnostic_path(alembic_diagnostics(:business_scorecard).slug)

      assert_response :success
      assert_select "h1", text: /Business Blind-Spot Scorecard/
    end

    test "the intro links into the stepper" do
      slug = alembic_diagnostics(:business_scorecard).slug

      get alembic.diagnostic_path(slug)

      assert_select "a[href=?]", alembic.diagnostic_step_path(slug)
    end

    test "an unknown slug is not found" do
      get alembic.diagnostic_path("does-not-exist")

      assert_response :not_found
    end

    test "a registered guide renders its explorable ladder" do
      get alembic.diagnostic_path("stats-system-ladder")

      assert_response :success
      assert_select "h1", text: /actually need to be/
      assert_select "summary", text: /Event log \+ rollups/
    end

    test "the ladder guide starts the stepper through its form" do
      get alembic.diagnostic_path("stats-system-ladder")

      assert_select "form[action=?]", alembic.diagnostic_step_path("stats-system-ladder")
    end

    test "a diagnostic with a definition renders its guide from the database" do
      get alembic.diagnostic_path("db-guide")

      assert_response :success
      assert_select "h1", text: /A guide defined in the database/
    end

    test "the stepper for a database guide renders its first question" do
      get alembic.diagnostic_step_path("db-guide")

      assert_response :success
      assert_select "legend", text: /Pick one option/
    end

    test "the stepper links back to the intro" do
      get alembic.diagnostic_step_path("stats-system-ladder")

      assert_select "a[href=?]", alembic.diagnostic_path("stats-system-ladder")
    end

    test "the stepper submits answers back to itself" do
      get alembic.diagnostic_step_path("stats-system-ladder")

      assert_select "form[action=?]", alembic.diagnostic_step_path("stats-system-ladder")
    end

    test "the stepper renders the first question" do
      get alembic.diagnostic_step_path("stats-system-ladder")

      assert_response :success
      assert_select "legend", text: /most advanced question/
    end

    test "answering a current-state need branches to the read question" do
      get alembic.diagnostic_step_path("stats-system-ladder"), params: { answers: { need: "now" } }

      assert_select "legend", text: /read.*versus how often/
    end

    def scored_diagnostic
      Diagnostic.create!(slug: "scored-flow", kind: "scored", definition: {
        "slug" => "scored-flow",
        "questions" => [
          { "id" => "need", "text" => "Need?", "options" => [ { "value" => "yes", "label" => "Yes", "weight" => 5 }, { "value" => "no", "label" => "No", "weight" => 0 } ] },
          { "id" => "team", "text" => "Team?", "options" => [ { "value" => "yes", "label" => "Yes", "weight" => 3 }, { "value" => "no", "label" => "No", "weight" => 0 } ] }
        ],
        "bands" => [ { "ceiling" => 4, "name" => "Flying blind" }, { "ceiling" => nil, "name" => "Well instrumented" } ]
      })
    end

    test "completing a scored diagnostic names the band the score lands in" do
      scored_diagnostic

      get alembic.diagnostic_step_path("scored-flow"), params: { answers: { need: "yes", team: "no" } }

      assert_select "h1", text: /Well instrumented/
    end

    test "the scored result links back to the intro" do
      scored_diagnostic

      get alembic.diagnostic_step_path("scored-flow"), params: { answers: { need: "yes", team: "no" } }

      assert_select "a[href=?]", alembic.diagnostic_path("scored-flow")
    end

    test "the scored result shows the total score" do
      scored_diagnostic

      get alembic.diagnostic_step_path("scored-flow"), params: { answers: { need: "yes", team: "no" } }

      assert_includes response.body, "Score: 5"
    end

    test "a scored diagnostic answered with no weight lands in the lowest band" do
      scored_diagnostic

      get alembic.diagnostic_step_path("scored-flow"), params: { answers: { need: "no", team: "no" } }

      assert_select "h1", text: /Flying blind/
    end

    test "the tier placement links back to the intro" do
      get alembic.diagnostic_step_path("stats-system-ladder"), params: { answers: { need: "rates", loss: "money", origin: "app" } }

      assert_select "a[href=?]", alembic.diagnostic_path("stats-system-ladder")
    end

    test "the tier placement links into the ladder section of the guide" do
      get alembic.diagnostic_step_path("stats-system-ladder"), params: { answers: { need: "rates", loss: "money", origin: "app" } }

      assert_select "a[href=?]", alembic.diagnostic_path("stats-system-ladder", anchor: "ladder")
    end

    test "completing the quiz reveals the tier placement" do
      get alembic.diagnostic_step_path("stats-system-ladder"), params: { answers: { need: "rates", loss: "money", origin: "app" } }

      assert_response :success
      assert_select "h1", text: /Event log \+ rollups/
    end

    def domain_diagnostic
      Diagnostic.create!(slug: "domain-flow", kind: "scored", definition: {
        "slug" => "domain-flow",
        "domains" => {
          "governance" => { "name" => "Governance", "gap_meaning" => "No one owns the decision", "gap_cost" => "Approvals stall for weeks" },
          "cash" => { "name" => "Cash", "gap_meaning" => "Runway is a guess", "gap_cost" => "Payroll surprises you" },
          "demand" => { "name" => "Demand", "gap_meaning" => "Pipeline is unread", "gap_cost" => "Quarters end blind" }
        },
        "questions" => [
          { "id" => "board", "text" => "Board?", "domain" => "governance", "options" => [ { "value" => "full", "label" => "Full", "weight" => 200 }, { "value" => "partial", "label" => "Partial", "weight" => 60 } ] },
          { "id" => "runway", "text" => "Runway?", "domain" => "cash", "options" => [ { "value" => "full", "label" => "Full", "weight" => 100 }, { "value" => "none", "label" => "None", "weight" => 0 } ] },
          { "id" => "pipeline", "text" => "Pipeline?", "domain" => "demand", "options" => [ { "value" => "full", "label" => "Full", "weight" => 80 } ] }
        ],
        "bands" => [ { "ceiling" => 50, "name" => "Flying blind" }, { "ceiling" => nil, "name" => "Well instrumented" } ]
      })
    end

    def domain_answers
      { board: "partial", runway: "none", pipeline: "full" }
    end

    test "a domain-scored result bands the overall percentage rather than the raw score" do
      domain_diagnostic

      get alembic.diagnostic_step_path("domain-flow"), params: { answers: domain_answers }

      assert_select "h1", text: /Flying blind/
    end

    test "a domain-scored result shows its overall percentage" do
      domain_diagnostic

      get alembic.diagnostic_step_path("domain-flow"), params: { answers: domain_answers }

      assert_includes response.body, "37%"
    end

    test "a domain-scored result lists each domain with its own percentage" do
      domain_diagnostic

      get alembic.diagnostic_step_path("domain-flow"), params: { answers: domain_answers }

      assert_select "li", text: /Governance.*30%/
    end

    test "a domain-scored result names its weakest domains as blind spots, weakest first" do
      domain_diagnostic

      get alembic.diagnostic_step_path("domain-flow"), params: { answers: domain_answers }

      assert_equal [ "Cash", "Governance" ], css_select("h3").map(&:text)
    end
  end
end
