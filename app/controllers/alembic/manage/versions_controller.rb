module Alembic
  module Manage
    class VersionsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @versions = @diagnostic.definition_versions.order(number: :desc)
      end
    end
  end
end
