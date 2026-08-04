module Alembic
  module Manage
    class BandsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @bands = @diagnostic.bands.order(:ceiling)
      end

      def create
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @diagnostic.bands.create!(band_params)
        redirect_to manage_diagnostic_bands_path(@diagnostic), notice: "Band added."
      end

      private

      def band_params
        params.require(:band).permit(:name, :ceiling, :description)
      end
    end
  end
end
