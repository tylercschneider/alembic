module Alembic
  module Manage
    class DiagnosticsController < BaseController
      def index
        @diagnostics = ordered_diagnostics
      end

      def create
        @diagnostic = Diagnostic.new(create_params)

        if @diagnostic.save
          redirect_to manage_diagnostic_path(@diagnostic), notice: "Diagnostic created."
        else
          @diagnostics = ordered_diagnostics
          render :index, status: :unprocessable_entity
        end
      end

      def show
        @diagnostic = Diagnostic.find(params[:id])
        @canvas = Flow::Canvas.new(Flow::Document.new(@diagnostic.definition || {})).to_h
          .merge("undoable" => @diagnostic.previous_definition_version.present?)
      end

      def edit
        @diagnostic = Diagnostic.find(params[:id])
      end

      def update
        @diagnostic = Diagnostic.find(params[:id])
        @diagnostic.update!(diagnostic_params)
        redirect_to manage_diagnostic_path(@diagnostic), notice: "Saved."
      end

      def destroy
        Diagnostic.find(params[:id]).destroy!
        redirect_to manage_diagnostics_path, notice: "Diagnostic removed."
      end

      private

      def ordered_diagnostics
        Diagnostic.order(:slug)
      end

      def create_params
        params.require(:diagnostic).permit(:slug, :kind)
      end

      def diagnostic_params
        params.require(:diagnostic).permit(:kicker, :headline, :blurb, :start_label, :resolver_key)
      end
    end
  end
end
