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

    test "the update action compiles the rows into the definition" do
      diagnostic = Diagnostic.create!(slug: "compilable", headline: "Compiled")

      post alembic.compile_manage_diagnostic_path(diagnostic)

      assert_equal "Compiled", diagnostic.reload.definition["headline"]
    end

    test "the revert action rebuilds rows from the definition" do
      diagnostic = Diagnostic.create!(slug: "revertable", definition: { "questions" => [ { "id" => "need", "text" => "Need?" } ] })

      post alembic.revert_manage_diagnostic_path(diagnostic)

      assert_equal [ "need" ], diagnostic.reload.questions.ordered.map(&:key)
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

    test "deleting a diagnostic removes its dependent rows" do
      diagnostic = Diagnostic.create!(slug: "cascade")
      diagnostic.questions.create!(key: "need")
      diagnostic.nodes.create!(key: "tier_one", kind: "tier")
      diagnostic.warnings.create!(key: "watch_out", text: "Careful.")
      diagnostic.bands.create!(name: "Low", ceiling: 5)
      diagnostic.rules.create!(position: 1)
        .results << diagnostic.results.create!(key: "r1", slot: "tier")

      delete alembic.manage_diagnostic_path(diagnostic)

      assert_empty [ Question, Node, Warning, Band, Result, Rule ]
        .flat_map { |model| model.where(diagnostic_id: diagnostic.id) }
    end

    test "the hub has update and revert buttons" do
      diagnostic = alembic_diagnostics(:business_scorecard)

      get alembic.manage_diagnostic_path(diagnostic)

      assert_select "form[action=?]", alembic.compile_manage_diagnostic_path(diagnostic)
      assert_select "form[action=?]", alembic.revert_manage_diagnostic_path(diagnostic)
    end
  end
end
