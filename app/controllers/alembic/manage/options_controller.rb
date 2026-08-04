module Alembic
  module Manage
    class OptionsController < BaseController
      def create
        @question = Diagnostic.find(params[:diagnostic_id]).questions.find(params[:question_id])
        @question.options.create!(value: "new")
        redirect_to edit_manage_diagnostic_question_path(@question.diagnostic, @question), notice: "Option added."
      end

      def move_up
        reorder(&:move_up)
      end

      def move_down
        reorder(&:move_down)
      end

      private

      def reorder
        @question = Diagnostic.find(params[:diagnostic_id]).questions.find(params[:question_id])
        yield @question.options.find(params[:id])
        redirect_to edit_manage_diagnostic_question_path(@question.diagnostic, @question), notice: "Order updated."
      end
    end
  end
end
