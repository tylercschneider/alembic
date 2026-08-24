module Alembic
  module Manage
    class DefinitionsController < BaseController
      def edit
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
      end
    end
  end
end
