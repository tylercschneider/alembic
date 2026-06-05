require "test_helper"

module Alembic
  class DiagnosticsFlowTest < ActionDispatch::IntegrationTest
    test "the intro renders the diagnostic title" do
      get alembic.diagnostic_path(alembic_diagnostics(:business_scorecard).slug)

      assert_response :success
      assert_select "h1", text: /Business Blind-Spot Scorecard/
    end
  end
end
