require "test_helper"

module Alembic
  class DiagnosticsBuilderTest < ActionDispatch::IntegrationTest
    test "the builder index lists the diagnostics" do
      get alembic.manage_diagnostics_path

      assert_includes response.body, "Business Blind-Spot Scorecard"
    end

    test "the builder shows a diagnostic" do
      get alembic.manage_diagnostic_path(alembic_flows(:business_scorecard))

      assert_includes response.body, "Business Blind-Spot Scorecard"
    end

    test "the builder index links each diagnostic to its hub" do
      get alembic.manage_diagnostics_path

      assert_select "a[href=?]", alembic.manage_diagnostic_path(alembic_flows(:business_scorecard))
    end

    test "the edit form prefills how the diagnostic is introduced" do
      diagnostic = Flow::Flow.create!(slug: "editme", title: "Current title")

      get alembic.edit_manage_diagnostic_path(diagnostic)

      assert_select "input[name=?][value=?]", "diagnostic[title]", "Current title"
    end

    test "updating saves how the diagnostic is introduced" do
      diagnostic = Flow::Flow.create!(slug: "editme", summary: "Old")

      patch alembic.manage_diagnostic_path(diagnostic), params: { diagnostic: { summary: "New summary" } }

      assert_equal "New summary", diagnostic.reload.summary
    end

    test "the hub offers the flow the way to its details" do
      diagnostic = alembic_flows(:business_scorecard)

      get alembic.manage_diagnostic_path(diagnostic)

      drawn = JSON.parse(css_select("[data-flow-canvas]").first["data-flow"])

      assert_equal alembic.edit_manage_diagnostic_path(diagnostic), drawn["flow"]["details_url"]
    end

    test "the builder index offers a form to create a diagnostic" do
      get alembic.manage_diagnostics_path

      assert_select "form[action=?] input[name=?]", alembic.manage_diagnostics_path, "diagnostic[slug]"
    end

    test "creating a diagnostic adds it" do
      assert_difference -> { Flow::Flow.count } do
        post alembic.manage_diagnostics_path, params: { diagnostic: { slug: "brand-new" } }
      end
    end

    test "creating a diagnostic without a slug re-renders with the error" do
      post alembic.manage_diagnostics_path, params: { diagnostic: { slug: "" } }

      assert_select "p", text: "Slug can't be blank"
    end

    test "the builder index offers a remove control per diagnostic" do
      get alembic.manage_diagnostics_path

      assert_select "form[action=?]", alembic.manage_diagnostic_path(alembic_flows(:business_scorecard))
    end

    test "deleting a diagnostic removes it" do
      diagnostic = Flow::Flow.create!(slug: "deleteme")

      delete alembic.manage_diagnostic_path(diagnostic)

      assert_not Flow::Flow.exists?(diagnostic.id)
    end

    test "the hub offers the flow the way to its definition" do
      diagnostic = alembic_flows(:business_scorecard)

      get alembic.manage_diagnostic_path(diagnostic)

      drawn = JSON.parse(css_select("[data-flow-canvas]").first["data-flow"])

      assert_equal alembic.edit_manage_diagnostic_definition_path(diagnostic), drawn["flow"]["definition_url"]
    end

    test "the definition editor offers the way back to the flow" do
      diagnostic = alembic_flows(:business_scorecard)

      get alembic.edit_manage_diagnostic_definition_path(diagnostic)

      assert_select "a[href=?]", alembic.manage_diagnostic_path(diagnostic)
    end

    test "the details editor offers the way back to the flow" do
      diagnostic = alembic_flows(:business_scorecard)

      get alembic.edit_manage_diagnostic_path(diagnostic)

      assert_select "a[href=?]", alembic.manage_diagnostic_path(diagnostic)
    end
  end
end
