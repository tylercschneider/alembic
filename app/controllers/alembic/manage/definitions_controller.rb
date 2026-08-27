module Alembic
  module Manage
    class DefinitionsController < BaseController
      def edit
        @diagnostic = Flow::Definition.find(params[:diagnostic_id])
      end

      def update
        @diagnostic = Flow::Definition.find(params[:diagnostic_id])
        @diagnostic.edit_document(JSON.parse(params.require(:definition)))
        redirect_to manage_diagnostic_path(@diagnostic), notice: "Definition saved."
      end
    end
  end
end
