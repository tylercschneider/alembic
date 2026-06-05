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
  end
end
