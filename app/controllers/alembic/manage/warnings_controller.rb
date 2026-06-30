module Alembic
  module Manage
    class WarningsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @warnings = @diagnostic.warnings.order(:key)
      end
    end
  end
end
