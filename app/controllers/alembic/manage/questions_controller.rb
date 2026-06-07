module Alembic
  module Manage
    class QuestionsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @questions = @diagnostic.questions.ordered
      end
    end
  end
end
