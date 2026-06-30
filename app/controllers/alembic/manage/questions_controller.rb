module Alembic
  module Manage
    class QuestionsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @questions = @diagnostic.questions.ordered
      end

      def create
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @question = @diagnostic.questions.create!(create_params)
        redirect_to edit_manage_diagnostic_question_path(@diagnostic, @question), notice: "Question added."
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

      def create_params
        params.require(:question).permit(:key).reverse_merge(
          text: "New question",
          position: @diagnostic.questions.maximum(:position).to_i + 1
        )
      end

      def question_params
        params.require(:question).permit(:text, options_attributes: [ :id, :value, :label, :hint, :_destroy ])
      end
    end
  end
end
