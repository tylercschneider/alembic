module Alembic
  module Manage
    class WarningsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @warnings = @diagnostic.warnings.order(:key)
      end

      def edit
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @warning = @diagnostic.warnings.find(params[:id])
      end

      def update
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @warning = @diagnostic.warnings.find(params[:id])
        @warning.update!(warning_params)
        redirect_to manage_diagnostic_warnings_path(@diagnostic), notice: "Saved."
      end

      private

      def warning_params
        params.require(:warning).permit(:key, :text)
      end
    end
  end
end
