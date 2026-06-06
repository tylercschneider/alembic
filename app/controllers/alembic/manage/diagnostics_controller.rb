module Alembic
  module Manage
    class DiagnosticsController < BaseController
      def index
        @diagnostics = Diagnostic.order(:slug)
      end

      def show
        @diagnostic = Diagnostic.find(params[:id])
      end
    end
  end
end
