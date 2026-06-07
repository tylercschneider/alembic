module Alembic
  module Manage
    class ConditionsController < BaseController
      def update
        @question = Diagnostic.find(params[:diagnostic_id]).questions.find(params[:question_id])
        option_ids = Array(params.dig(:condition, :option_ids)).reject(&:blank?)

        if option_ids.empty?
          @question.conditions.destroy_all
        else
          condition = @question.conditions.first_or_initialize
          condition.tested_question = Option.find(option_ids.first).question
          condition.option_ids = option_ids
          condition.save!
        end

        redirect_to edit_manage_diagnostic_question_path(@question.diagnostic, @question), notice: "Condition saved."
      end
    end
  end
end
