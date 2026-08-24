module Alembic
  module Manage
    class CanvasController < BaseController
      def show
        @diagnostic = diagnostic
        @canvas = Flow::Canvas.new(document).to_h

        respond_to do |format|
          format.html
          format.json { render json: @canvas }
        end
      end

      def add_step
        apply { |flow| placed_on_edge? ? flow.insert(new_step, on: edge_endpoints) : flow.add(new_step) }
      end

      def configure_step
        apply { |flow| flow.configure(params[:step], configuration) }
      end

      def remove_step
        apply { |flow| flow.remove(params[:step]) }
      end

      def connect
        apply { |flow| flow.connect(from: params[:from], to: params[:to], on: params[:on].presence) }
      end

      def disconnect
        apply { |flow| flow.disconnect(from: params[:from], to: params[:to]) }
      end

      private

      def apply
        diagnostic.record_definition(yield(document).to_h)
        head :no_content
      rescue Flow::InvalidEdit => invalid
        render json: { error: invalid.message }, status: :unprocessable_entity
      end

      def diagnostic
        @diagnostic ||= Diagnostic.find(params[:diagnostic_id])
      end

      def document
        Flow::Document.new(diagnostic.definition || {})
      end

      def new_step
        { "id" => params.require(:id), "type" => params.require(:type) }
      end

      def placed_on_edge?
        params[:from].present? && params[:to].present?
      end

      def edge_endpoints
        [ params[:from], params[:to] ]
      end

      def configuration
        params.fetch(:config, {}).permit!.to_h
      end
    end
  end
end
