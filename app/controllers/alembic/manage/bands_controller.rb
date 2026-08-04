module Alembic
  module Manage
    class BandsController < BaseController
      def index
        @diagnostic = Diagnostic.find(params[:diagnostic_id])
        @bands = @diagnostic.bands.order(:ceiling)
      end
    end
  end
end
