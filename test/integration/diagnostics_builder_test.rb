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

    test "the edit form prefills the diagnostic copy" do
      diagnostic = Diagnostic.create!(slug: "editme", headline: "Current headline")

      get alembic.edit_manage_diagnostic_path(diagnostic)

      assert_select "input[name=?][value=?]", "diagnostic[headline]", "Current headline"
    end

    test "updating saves the diagnostic copy" do
      diagnostic = Diagnostic.create!(slug: "editme", headline: "Old")

      patch alembic.manage_diagnostic_path(diagnostic), params: { diagnostic: { headline: "New headline" } }

      assert_equal "New headline", diagnostic.reload.headline
    end

    test "the hub links to the edit form" do
      diagnostic = alembic_diagnostics(:business_scorecard)

      get alembic.manage_diagnostic_path(diagnostic)

      assert_select "a[href=?]", alembic.edit_manage_diagnostic_path(diagnostic)
    end

    test "the builder index offers a form to create a diagnostic" do
      get alembic.manage_diagnostics_path

      assert_select "form[action=?] input[name=?]", alembic.manage_diagnostics_path, "diagnostic[slug]"
    end

    test "creating a diagnostic adds it" do
      assert_difference -> { Diagnostic.count } do
        post alembic.manage_diagnostics_path, params: { diagnostic: { slug: "brand-new" } }
      end
    end

    test "creating a diagnostic without a slug re-renders with the error" do
      post alembic.manage_diagnostics_path, params: { diagnostic: { slug: "" } }

      assert_select "p", text: "Slug can't be blank"
    end

    test "the builder index offers a remove control per diagnostic" do
      get alembic.manage_diagnostics_path

      assert_select "form[action=?]", alembic.manage_diagnostic_path(alembic_diagnostics(:business_scorecard))
    end

    test "deleting a diagnostic removes it" do
      diagnostic = Diagnostic.create!(slug: "deleteme")

      delete alembic.manage_diagnostic_path(diagnostic)

      assert_not Diagnostic.exists?(diagnostic.id)
    end

    test "the hub links to the definition editor" do
      diagnostic = alembic_diagnostics(:business_scorecard)

      get alembic.manage_diagnostic_path(diagnostic)

      assert_select "a[href=?]", alembic.edit_manage_diagnostic_definition_path(diagnostic)
    end
  end
end
