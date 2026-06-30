require "test_helper"

module Alembic
  class WarningsBuilderTest < ActionDispatch::IntegrationTest
    test "the warnings index lists the diagnostic's warnings" do
      diagnostic = Diagnostic.create!(slug: "warnings")
      diagnostic.warnings.create!(key: "money_pairing", text: "Money-grade pairing.")

      get alembic.manage_diagnostic_warnings_path(diagnostic)

      assert_includes response.body, "Money-grade pairing."
    end

    test "the hub links to the warnings editor" do
      diagnostic = alembic_diagnostics(:stats_ladder)

      get alembic.manage_diagnostic_path(diagnostic)

      assert_select "a[href=?]", alembic.manage_diagnostic_warnings_path(diagnostic)
    end
  end
end
