module Alembic
  module Manage
    class DefinitionsController < BaseController
      def edit
        @diagnostic = Flow::Definition.find(params[:flow_id])
      end

      def update
        @diagnostic = Flow::Definition.find(params[:flow_id])
        @diagnostic.edit_document(JSON.parse(params.require(:definition)))
        redirect_to manage_flow_path(@diagnostic), notice: "Definition saved."
      end
    end
  end
end
