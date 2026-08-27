module Alembic
  module Manage
    class PreviewsController < ::Alembic::DiagnosticsController
      include AuthenticatesAdmin

      def show
        @diagnostic = previewed
        render template: "alembic/diagnostics/show"
      end

      private

      def flow_start_path(_slug)
        alembic.manage_diagnostic_preview_path(previewed)
      end

      def flow_step_path(_slug)
        alembic.step_manage_diagnostic_preview_path(previewed)
      end

      def previewing?
        true
      end

      def flowing_definition(diagnostic)
        diagnostic.document
      end

      def previewed
        @previewed ||= Flow::Flow.find(params[:diagnostic_id])
      end

      def admit(_diagnostic)
        previewed
      end
    end
  end
end
