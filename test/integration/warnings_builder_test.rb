require "test_helper"

module Alembic
  class WarningsBuilderTest < ActionDispatch::IntegrationTest
    test "the warnings index lists the diagnostic's warnings" do
      diagnostic = Diagnostic.create!(slug: "warnings")
      diagnostic.warnings.create!(key: "money_pairing", text: "Money-grade pairing.")

      get alembic.manage_diagnostic_warnings_path(diagnostic)

      assert_includes response.body, "Money-grade pairing."
    end
  end
end
