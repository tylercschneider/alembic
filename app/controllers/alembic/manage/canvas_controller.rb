module Alembic
  module Manage
    class CanvasController < BaseController
      def show
        render json: Flow::Canvas.new(document).to_h.merge("undoable" => diagnostic.previous_definition_version.present?)
      end

      def undo
        undoing = diagnostic.previous_definition_version
        diagnostic.record_definition(undoing.definition) if undoing

        head :no_content
      end

      def add_step
        apply do |flow|
          next flow.insert(new_step, on: edge_endpoints, leaving: first_port) if placed_on_edge?
          next flow.add(new_step).connect(from: params[:from], to: params[:id], on: params[:on].presence) if branched_from?

          flow.add(new_step)
        end
      end

      def configure_step
        apply { |flow| flow.configure(params[:step], configuration) }
      end

      def move_step
        apply { |flow| flow.move(params[:step], on: edge_endpoints, leaving: port_for(params[:step])) }
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

      def first_port
        port_for_type(params[:type])
      end

      def port_for(id)
        port_for_type(document.node(id)&.type)
      end

      def port_for_type(type)
        Flow.registry.fetch(type).ports.first&.to_s if Flow.registry.registered?(type)
      end

      def placed_on_edge?
        params[:from].present? && params[:to].present?
      end

      def branched_from?
        params[:from].present?
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
