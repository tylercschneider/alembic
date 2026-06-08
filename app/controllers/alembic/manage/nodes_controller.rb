module Alembic
  module Manage
    class NodesController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @nodes = @diagnostic.nodes.order(:kind, :position)
      end
    end
  end
end
