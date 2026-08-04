module Alembic
  module Manage
    class NodesController < BaseController
      TEXT_FIELDS = %i[tagline complexity setup maintenance captures why pains avoid avoid_pain].freeze

      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @nodes = @diagnostic.nodes.order(:kind, :position)
      end

      def create
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @node = @diagnostic.nodes.create!(create_params)
        redirect_to edit_manage_diagnostic_node_path(@diagnostic, @node), notice: "Node added."
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

      def move_down
        reorder(&:move_down)
      end

      def destroy
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @diagnostic.nodes.find(params[:id]).destroy!
        redirect_to manage_diagnostic_nodes_path(@diagnostic), notice: "Node removed."
      end

      private

      def reorder
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        yield @diagnostic.nodes.find(params[:id])
        redirect_to manage_diagnostic_nodes_path(@diagnostic), notice: "Order updated."
      end

      def create_params
        params.require(:node).permit(:kind, :key).reverse_merge(
          name: "New node",
          position: @diagnostic.nodes.maximum(:position).to_i + 1
        )
      end

      def node_params
        params.require(:node).permit(:name, *TEXT_FIELDS, build_steps_attributes: [ :id, :title, :code, :position, :_destroy ])
      end
    end
  end
end
