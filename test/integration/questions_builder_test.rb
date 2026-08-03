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

    test "the question edit form renders a remove checkbox for each option" do
      diagnostic = Diagnostic.create!(slug: "qopts")
      question = diagnostic.questions.create!(key: "need", text: "Q", position: 1)
      question.options.create!(value: "now", position: 1)

      get alembic.edit_manage_diagnostic_question_path(diagnostic, question)

      assert_select "input[type=checkbox][name=?]", "question[options_attributes][0][_destroy]"
    end

    test "adding an option creates one on the question" do
      diagnostic = Diagnostic.create!(slug: "addopt")
      question = diagnostic.questions.create!(key: "need", position: 1)

      assert_difference -> { question.options.count } do
        post alembic.manage_diagnostic_question_options_path(diagnostic, question)
      end
    end

    test "the question edit form has an add-option button" do
      diagnostic = Diagnostic.create!(slug: "addopt")
      question = diagnostic.questions.create!(key: "need", text: "Q", position: 1)

      get alembic.edit_manage_diagnostic_question_path(diagnostic, question)

      assert_select "form[action=?]", alembic.manage_diagnostic_question_options_path(diagnostic, question)
    end

    test "creating a question adds one to the diagnostic" do
      diagnostic = Diagnostic.create!(slug: "addq")

      assert_difference -> { diagnostic.questions.count } do
        post alembic.manage_diagnostic_questions_path(diagnostic), params: { question: { key: "budget" } }
      end
    end

    test "the questions index has an add-question form" do
      diagnostic = Diagnostic.create!(slug: "addq")

      get alembic.manage_diagnostic_questions_path(diagnostic)

      assert_select "form[action=?]", alembic.manage_diagnostic_questions_path(diagnostic)
    end

    test "destroying a question removes it from the diagnostic" do
      diagnostic = Diagnostic.create!(slug: "delq")
      question = diagnostic.questions.create!(key: "need", text: "Q", position: 1)

      assert_difference -> { diagnostic.questions.count }, -1 do
        delete alembic.manage_diagnostic_question_path(diagnostic, question)
      end
    end

    test "the questions index has a remove control for each question" do
      diagnostic = Diagnostic.create!(slug: "delq")
      question = diagnostic.questions.create!(key: "need", text: "Q", position: 1)

      get alembic.manage_diagnostic_questions_path(diagnostic)

      assert_select "form[action=?]", alembic.manage_diagnostic_question_path(diagnostic, question)
    end

    test "moving a question down from the index reorders it" do
      diagnostic = Diagnostic.create!(slug: "moveq")
      first = diagnostic.questions.create!(key: "a", position: 1)
      diagnostic.questions.create!(key: "b", position: 2)

      post alembic.move_down_manage_diagnostic_question_path(diagnostic, first)

      assert_equal [ "b", "a" ], diagnostic.questions.ordered.map(&:key)
    end

    test "moving a question up from the index reorders it" do
      diagnostic = Diagnostic.create!(slug: "moveq")
      diagnostic.questions.create!(key: "a", position: 1)
      last = diagnostic.questions.create!(key: "b", position: 2)

      post alembic.move_up_manage_diagnostic_question_path(diagnostic, last)

      assert_equal [ "b", "a" ], diagnostic.questions.ordered.map(&:key)
    end

    test "moving an option down from the question edit form reorders it" do
      diagnostic = Diagnostic.create!(slug: "moveopt")
      question = diagnostic.questions.create!(key: "q", position: 1)
      first = question.options.create!(value: "a", position: 1)
      question.options.create!(value: "b", position: 2)

      post alembic.move_down_manage_diagnostic_question_option_path(diagnostic, question, first)

      assert_equal [ "b", "a" ], question.options.ordered.map(&:value)
    end

    test "moving an option up from the question edit form reorders it" do
      diagnostic = Diagnostic.create!(slug: "moveopt")
      question = diagnostic.questions.create!(key: "q", position: 1)
      question.options.create!(value: "a", position: 1)
      last = question.options.create!(value: "b", position: 2)

      post alembic.move_up_manage_diagnostic_question_option_path(diagnostic, question, last)

      assert_equal [ "b", "a" ], question.options.ordered.map(&:value)
    end

    test "a destroyed question leaves no trace in the compiled definition after Update" do
      diagnostic = Diagnostic.create!(slug: "delq")
      need = diagnostic.questions.create!(key: "need", text: "Q", position: 1)
      rates = need.options.create!(value: "rates", position: 1)
      loss = diagnostic.questions.create!(key: "loss", text: "Q", position: 2)
      loss.conditions.create!(tested_question: need, options: [ rates ])

      delete alembic.manage_diagnostic_question_path(diagnostic, need)
      post alembic.compile_manage_diagnostic_path(diagnostic)

      compiled = diagnostic.reload.definition["questions"]
      assert_equal [ "loss" ], compiled.map { |question| question["id"] }
      assert_nil compiled.first["condition"]
    end
  end
end
