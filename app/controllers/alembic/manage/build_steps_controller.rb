module Alembic
  module Manage
    class BuildStepsController < BaseController
      def create
        diagnostic = Diagnostic.find(params[:diagnostic_id])
        @node = diagnostic.nodes.find(params[:node_id])
        @node.build_steps.create!(title: "New step")
        redirect_to edit_manage_diagnostic_node_path(diagnostic, @node), notice: "Build step added."
      end

      def move_down
        reorder(&:move_down)
      end

      private

      def reorder
        diagnostic = Diagnostic.find(params[:diagnostic_id])
        @node = diagnostic.nodes.find(params[:node_id])
        yield @node.build_steps.find(params[:id])
        redirect_to edit_manage_diagnostic_node_path(diagnostic, @node), notice: "Order updated."
      end
    end
  end
end
