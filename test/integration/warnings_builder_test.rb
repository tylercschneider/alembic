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

    test "the warning edit form prefills the warning text" do
      diagnostic = Diagnostic.create!(slug: "warnings")
      warning = diagnostic.warnings.create!(key: "money_pairing", text: "Money-grade pairing.")

      get alembic.edit_manage_diagnostic_warning_path(diagnostic, warning)

      assert_select "textarea[name=?]", "warning[text]", text: "Money-grade pairing."
    end

    test "updating a warning saves the text" do
      diagnostic = Diagnostic.create!(slug: "warnings")
      warning = diagnostic.warnings.create!(key: "money_pairing", text: "old")

      patch alembic.manage_diagnostic_warning_path(diagnostic, warning), params: { warning: { text: "new" } }

      assert_equal "new", warning.reload.text
    end

    test "the warnings index links each warning to its edit form" do
      diagnostic = Diagnostic.create!(slug: "warnings")
      warning = diagnostic.warnings.create!(key: "money_pairing", text: "x")

      get alembic.manage_diagnostic_warnings_path(diagnostic)

      assert_select "a[href=?]", alembic.edit_manage_diagnostic_warning_path(diagnostic, warning)
    end
  end
end
