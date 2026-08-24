module Alembic
  module Manage
    class StepsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @steps = Array(@diagnostic.definition&.fetch("questions", nil))
      end
    end
  end
end
