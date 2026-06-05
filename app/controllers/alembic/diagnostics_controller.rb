module Alembic
  class DiagnosticsController < ApplicationController
    def show
      @diagnostic = Diagnostic.find_by!(slug: params[:slug])
    end
  end
end
