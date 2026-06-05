module Alembic
  class DiagnosticsController < ApplicationController
    def show
      @guide = Alembic::Guide.find(params[:slug])
      return render :guide if @guide

      @diagnostic = Diagnostic.find_by!(slug: params[:slug])
    end
  end
end
