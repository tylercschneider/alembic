module Alembic
  module Manage
    class PreviewsController < ::Alembic::FlowsController
      include AuthenticatesAdmin

      def show
        @diagnostic = previewed
        render template: "alembic/flows/show"
      end

      private

      def flow_start_path(_slug)
        alembic.manage_flow_preview_path(previewed)
      end

      def flow_step_path(_slug)
        alembic.step_manage_flow_preview_path(previewed)
      end

      def previewing?
        true
      end

      def flowing_definition(diagnostic)
        diagnostic.document
      end

      def previewed
        @previewed ||= Flow::Definition.find(params[:flow_id])
      end

      def admit(_diagnostic)
        previewed
      end
    end
  end
end
