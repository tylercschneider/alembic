require "test_helper"

module Alembic
  class DiagnosticsBuilderTest < ActionDispatch::IntegrationTest
    test "the builder index lists the diagnostics" do
      get alembic.manage_diagnostics_path

      assert_includes response.body, "Business Blind-Spot Scorecard"
    end
  end
end
