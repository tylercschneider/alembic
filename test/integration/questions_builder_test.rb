require "test_helper"

module Alembic
  class QuestionsBuilderTest < ActionDispatch::IntegrationTest
    test "the questions index lists the diagnostic's questions" do
      diagnostic = alembic_diagnostics(:stats_ladder)

      get alembic.manage_diagnostic_questions_path(diagnostic)

      assert_includes response.body, "need"
    end

    test "the hub links to the questions module" do
      diagnostic = alembic_diagnostics(:stats_ladder)

      get alembic.manage_diagnostic_path(diagnostic)

      assert_select "a[href=?]", alembic.manage_diagnostic_questions_path(diagnostic)
    end
  end
end
