module Alembic
  module Manage
    class StepsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @steps = Array(@diagnostic.definition&.fetch("questions", nil))
      end

      def reorder
        diagnostic = Diagnostic.find(params[:diagnostic_id])
        diagnostic.record_definition(DefinitionDocument.new(diagnostic.definition).reorder(ordered_ids))
        head :no_content
      end

      private

      def ordered_ids
        Array(params[:ids]).map(&:to_s)
      end
    end
  end
end
