module Alembic
  module Manage
    class WarningsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @warnings = @diagnostic.warnings.order(:key)
      end

      def create
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @warning = @diagnostic.warnings.create!(create_params)
        redirect_to edit_manage_diagnostic_warning_path(@diagnostic, @warning), notice: "Warning added."
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

      def destroy
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @diagnostic.warnings.find(params[:id]).destroy!
        redirect_to manage_diagnostic_warnings_path(@diagnostic), notice: "Warning removed."
      end

      private

      def create_params
        params.require(:warning).permit(:key).reverse_merge(text: "New warning.")
      end

      def warning_params
        params.require(:warning).permit(:key, :text)
      end
    end
  end
end
