module Alembic
  module Manage
    class QuestionsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @questions = @diagnostic.questions.ordered
      end

      def edit
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @question = @diagnostic.questions.find(params[:id])
      end

      def update
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @question = @diagnostic.questions.find(params[:id])
        @question.update!(question_params)
        redirect_to manage_diagnostic_questions_path(@diagnostic), notice: "Saved."
      end

      private

      def question_params
        params.require(:question).permit(:text, options_attributes: [ :id, :value, :label, :hint, :_destroy ])
      end
    end
  end
end
