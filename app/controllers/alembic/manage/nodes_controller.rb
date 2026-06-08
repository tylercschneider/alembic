module Alembic
  module Manage
    class NodesController < BaseController
      TEXT_FIELDS = %i[tagline complexity setup maintenance captures why pains avoid avoid_pain].freeze

      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @nodes = @diagnostic.nodes.order(:kind, :position)
      end

      def edit
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @node = @diagnostic.nodes.find(params[:id])
      end

      def update
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @node = @diagnostic.nodes.find(params[:id])
        @node.update!(node_params)
        redirect_to manage_diagnostic_nodes_path(@diagnostic), notice: "Saved."
      end

      private

      def node_params
        params.require(:node).permit(:name, *TEXT_FIELDS)
      end
    end
  end
end
