require "test_helper"

module Alembic
  class DiagnosticsBuilderTest < ActionDispatch::IntegrationTest
    test "the builder index lists the diagnostics" do
      get alembic.manage_diagnostics_path

      assert_includes response.body, "Business Blind-Spot Scorecard"
    end

    test "the builder shows a diagnostic" do
      get alembic.manage_diagnostic_path(alembic_diagnostics(:business_scorecard))

      assert_includes response.body, "Business Blind-Spot Scorecard"
    end

    test "the builder index links each diagnostic to its hub" do
      get alembic.manage_diagnostics_path

      assert_select "a[href=?]", alembic.manage_diagnostic_path(alembic_diagnostics(:business_scorecard))
    end
  end
end
