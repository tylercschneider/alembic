module Alembic
  module Manage
    class PreviewsController < ::Alembic::DiagnosticsController
      include AuthenticatesAdmin

      def show
        @diagnostic = previewed
        render template: "alembic/diagnostics/show"
      end

      private

      def previewed
        @previewed ||= Diagnostic.find(params[:diagnostic_id])
      end

      def admit(_diagnostic)
        previewed
      end
    end
  end
end
