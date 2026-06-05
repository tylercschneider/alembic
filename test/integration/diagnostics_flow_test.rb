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

    test "the stepper renders the first question" do
      get alembic.diagnostic_step_path("stats-system-ladder")

      assert_response :success
      assert_select "legend", text: /most advanced question/
    end

    test "answering a current-state need branches to the read question" do
      get alembic.diagnostic_step_path("stats-system-ladder"), params: { answers: { need: "now" } }

      assert_select "legend", text: /read.*versus how often/
    end

    test "completing the quiz reveals the tier placement" do
      get alembic.diagnostic_step_path("stats-system-ladder"), params: { answers: { need: "rates", loss: "money", origin: "app" } }

      assert_response :success
      assert_select "h1", text: /Event log \+ rollups/
    end
  end
end
