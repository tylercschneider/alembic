module Alembic
  module Manage
    class CanvasController < BaseController
      def show
        render json: canvas_payload
      end

      def cut
        diagnostic.cut_version
        head :no_content
      end

      def undo
        diagnostic.undo_definition
        head :no_content
      end

      def redo
        diagnostic.redo_definition
        head :no_content
      end

      def add_step
        apply(:added, params[:id]) do |flow|
          next flow.insert(new_step, on: edge_endpoints, leaving: first_port) if placed_on_edge?
          next flow.add(new_step).connect(from: params[:from], to: params[:id], on: params[:on].presence) if branched_from?

          flow.add(new_step)
        end
      end

      def configure_step
        apply(:updated, params[:step]) { |flow| flow.configure(params[:step], coerced(flow, params[:step])) }
      end

      def move_step
        apply(:moved, params[:step]) { |flow| flow.move(params[:step], on: edge_endpoints, leaving: port_for(params[:step])) }
      end

      def remove_step
        apply(:removed, params[:step]) { |flow| flow.remove(params[:step]) }
      end

      def connect
        apply(:connected, params[:from], params[:to]) { |flow| flow.connect(from: params[:from], to: params[:to], on: params[:on].presence) }
      end

      def disconnect
        apply(:disconnected, params[:from], params[:to]) { |flow| flow.disconnect(from: params[:from], to: params[:to]) }
      end

      private

      def apply(action = nil, *steps)
        edited = yield(document)
        diagnostic.update!(document: edited.to_h, changes_since_version: recorded(action, edited, steps))
        head :no_content
      rescue Flow::InvalidEdit => invalid
        render json: { error: invalid.message }, status: :unprocessable_entity
      end

      def canvas_payload
        Flow::Canvas.new(document).to_h
          .merge("undoable" => diagnostic.undoable?, "redoable" => diagnostic.redoable?)
      end

      def diagnostic
        @diagnostic ||= Diagnostic.find(params[:diagnostic_id])
      end

      def document
        Flow::Document.new(diagnostic.document || diagnostic.definition || {})
      end

      def recorded(action, edited, steps)
        return diagnostic.changes_since_version.to_a unless action

        diagnostic.changes_since_version.to_a +
          [ { "action" => action.to_s, "steps" => steps.map(&:to_s), "named" => steps.map { |id| named(edited, id) } } ]
      end

      def named(edited, id)
        Flow::Name.of(edited.node(id.to_s) || document.node(id.to_s))
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

      def coerced(flow, id)
        step_type = Flow::Digest.new(flow).step(id)&.type
        return configuration unless step_type && Flow.registry.registered?(step_type)

        settled(Flow.registry.fetch(step_type))
      end

      def settled(step_type)
        step_type.coerce(configuration).tap do |values|
          objections = step_type.objections(values)
          raise Flow::InvalidEdit, objections.join(", ") if objections.any?
        end
      end
    end
  end
end
