module Alembic
  module Manage
    class FlowsController < BaseController
      include DrawsCanvas
      def index
        @diagnostics = ordered_diagnostics
      end

      def create
        @diagnostic = Flow::Definition.new(create_params)

        if @diagnostic.save
          redirect_to manage_flow_path(@diagnostic), notice: "Flow created."
        else
          @diagnostics = ordered_diagnostics
          render :index, status: :unprocessable_entity
        end
      end

      def show
        @diagnostic = Flow::Definition.find(params[:id])
        @canvas = canvas_payload(@diagnostic)
      end

      def edit
        @diagnostic = Flow::Definition.find(params[:id])
      end

      def update
        @diagnostic = Flow::Definition.find(params[:id])
        @diagnostic.update!(diagnostic_params)
        redirect_to manage_flow_path(@diagnostic), notice: "Saved."
      end

      def destroy
        Flow::Definition.find(params[:id]).destroy!
        redirect_to manage_flows_path, notice: "Flow removed."
      end

      private

      def ordered_diagnostics
        Flow::Definition.order(:slug)
      end

      def create_params
        params.require(:flow).permit(:slug, :kind)
      end

      def diagnostic_params
        params.require(:flow).permit(:title, :summary, :start_label, :persists)
      end
    end
  end
end
