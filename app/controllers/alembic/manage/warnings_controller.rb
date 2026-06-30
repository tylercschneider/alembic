module Alembic
  module Manage
    class WarningsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @warnings = @diagnostic.warnings.order(:key)
      end

      def edit
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @warning = @diagnostic.warnings.find(params[:id])
      end
    end
  end
end
