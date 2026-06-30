module Alembic
  module Manage
    class BuildStepsController < BaseController
      def create
        diagnostic = Diagnostic.find(params[:diagnostic_id])
        @node = diagnostic.nodes.find(params[:node_id])
        @node.build_steps.create!(title: "New step")
        redirect_to edit_manage_diagnostic_node_path(diagnostic, @node), notice: "Build step added."
      end
    end
  end
end
