module Alembic
  module Manage
    class OptionsController < BaseController
      def create
        @question = Diagnostic.find(params[:diagnostic_id]).questions.find(params[:question_id])
        @question.options.create!(value: "new")
        redirect_to edit_manage_diagnostic_question_path(@question.diagnostic, @question), notice: "Option added."
      end
    end
  end
end
