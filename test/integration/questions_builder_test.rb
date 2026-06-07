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

    test "the question edit form prefills the text" do
      diagnostic = Diagnostic.create!(slug: "qedit")
      question = diagnostic.questions.create!(key: "need", text: "What do you need?", position: 1)

      get alembic.edit_manage_diagnostic_question_path(diagnostic, question)

      assert_select "input[name=?][value=?]", "question[text]", "What do you need?"
    end

    test "updating a question saves its text" do
      diagnostic = Diagnostic.create!(slug: "qedit")
      question = diagnostic.questions.create!(key: "need", text: "Old", position: 1)

      patch alembic.manage_diagnostic_question_path(diagnostic, question), params: { question: { text: "New text" } }

      assert_equal "New text", question.reload.text
    end

    test "the questions index links each question to its edit form" do
      diagnostic = Diagnostic.create!(slug: "qedit")
      question = diagnostic.questions.create!(key: "need", text: "Q", position: 1)

      get alembic.manage_diagnostic_questions_path(diagnostic)

      assert_select "a[href=?]", alembic.edit_manage_diagnostic_question_path(diagnostic, question)
    end

    test "updating a question saves an option change" do
      diagnostic = Diagnostic.create!(slug: "qopts")
      question = diagnostic.questions.create!(key: "need", text: "Q", position: 1)
      option = question.options.create!(value: "now", label: "Now", position: 1)

      patch alembic.manage_diagnostic_question_path(diagnostic, question), params: { question: { options_attributes: [ { id: option.id, label: "Right now" } ] } }

      assert_equal "Right now", option.reload.label
    end

    test "the question edit form renders a field for each option" do
      diagnostic = Diagnostic.create!(slug: "qopts")
      question = diagnostic.questions.create!(key: "need", text: "Q", position: 1)
      question.options.create!(value: "now", label: "Now", position: 1)

      get alembic.edit_manage_diagnostic_question_path(diagnostic, question)

      assert_select "input[name=?][value=?]", "question[options_attributes][0][label]", "Now"
    end
  end
end
