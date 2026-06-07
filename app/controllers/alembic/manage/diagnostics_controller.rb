module Alembic
  module Manage
    class DiagnosticsController < BaseController
      def index
        @diagnostics = Diagnostic.order(:slug)
      end

      def show
        @diagnostic = Diagnostic.find(params[:id])
      end

      def edit
        @diagnostic = Diagnostic.find(params[:id])
      end

      def update
        @diagnostic = Diagnostic.find(params[:id])
        @diagnostic.update!(diagnostic_params)
        redirect_to manage_diagnostic_path(@diagnostic), notice: "Saved."
      end

      def compile
        @diagnostic = Diagnostic.find(params[:id])
        @diagnostic.compile!
        redirect_to manage_diagnostic_path(@diagnostic), notice: "Published the current rows."
      end

      def revert
        @diagnostic = Diagnostic.find(params[:id])
        @diagnostic.revert!
        redirect_to manage_diagnostic_path(@diagnostic), notice: "Reverted to the published definition."
      end

      private

      def diagnostic_params
        params.require(:diagnostic).permit(:kicker, :headline, :blurb, :start_label, :resolver_key)
      end
    end
  end
end
