module Alembic
  module Manage
    class CanvasController < BaseController
      include DrawsCanvas
      def show
        render json: canvas_payload(diagnostic)
      end

      def create
        stood_at = diagnostic.current_definition_version&.number
        diagnostic.create_version

        render json: { notice: created(stood_at) }
      end

      def publish
        objections = Flow::Validator.new(document).violations
        return render json: { error: refusal(objections) }, status: :unprocessable_entity if objections.any?

        ran = diagnostic.live_version&.number
        diagnostic.publish

        render json: { notice: published(ran) }
      end

      def details
        diagnostic.update!(details_params)
        render json: { notice: "Saved the flow's details." }
      end

      def undo
        diagnostic.undo_change
        head :no_content
      end

      def redo
        diagnostic.redo_change
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
        before = document.to_h
        edited = yield(document)
        diagnostic.update!(document: edited.to_h, undone_changes: [],
          changes_since_version: recorded(action, edited, steps, before))
        head :no_content
      rescue Flow::InvalidEdit => invalid
        render json: { error: invalid.message }, status: :unprocessable_entity
      end

      def diagnostic
        @diagnostic ||= Diagnostic.find(params[:diagnostic_id])
      end

      def document
        Flow::Document.new(diagnostic.document || diagnostic.definition || {})
      end

      def details_params
        params.require(:diagnostic).permit(:title, :summary, :start_label)
      end

      def recorded(action, edited, steps, before)
        return diagnostic.changes_since_version.to_a unless action

        diagnostic.changes_since_version.to_a +
          [ { "action" => action.to_s, "steps" => steps.map(&:to_s),
              "named" => steps.map { |id| named(edited, id) }, "before" => before } ]
      end

      def named(edited, id)
        Flow::Name.of(edited.node(id.to_s) || document.node(id.to_s))
      end

      def new_step
        { "id" => params.require(:id), "type" => params.require(:type) }
      end

      def first_port
        first_value_of(Flow::Node.new(id: nil, type: params[:type], config: {}))
      end

      def port_for(id)
        first_value_of(document.node(id))
      end

      def first_value_of(node)
        return unless node && Flow.registry.registered?(node.type)

        step_type = Flow.registry.fetch(node.type)
        return unless step_type.routes?

        step_type.outputs.flat_map { |output| output.values_for(node) }.first&.fetch("value", nil)&.to_s
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

      def created(stood_at)
        now_at = diagnostic.reload.current_definition_version&.number
        return "Nothing has changed since version #{stood_at}." if now_at == stood_at

        "Created version #{now_at}."
      end

      def published(ran)
        now_at = diagnostic.reload.live_version&.number
        return "Visitors already run version #{now_at}." if now_at == ran

        "Published version #{now_at}. Visitors run it now."
      end

      def refusal(objections)
        "Cannot publish: #{objections.map { |problem| worded(problem) }.join(', ')}."
      end

      def worded(problem)
        trouble = problem.problem.to_s.humanize(capitalize: false)

        problem.node ? "“#{problem.node}” is #{trouble}" : trouble
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
