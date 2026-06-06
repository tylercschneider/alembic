module Alembic
  module Manage
    class DiagnosticsController < BaseController
      def index
        @diagnostics = Diagnostic.order(:slug)
      end
    end
  end
end
