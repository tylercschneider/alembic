module Alembic
  module Manage
    class VersionsController < BaseController
      def index
        @diagnostic = diagnostic
        @versions = @diagnostic.definition_versions.order(number: :desc)
      end

      def return
        diagnostic.return_to(diagnostic.definition_versions.find(params[:id]))

        redirect_to manage_flow_path(diagnostic), notice: "The flow is back to that version."
      end

      private

      def diagnostic
        @diagnostic ||= Flow::Definition.find(params[:flow_id])
      end
    end
  end
end
