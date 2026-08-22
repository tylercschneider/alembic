module Alembic
  class ResponsesController < ApplicationController
    def create
      redirect_to response_path(Response.start(diagnostic))
    end

    private

    def diagnostic
      Diagnostic.find_by!(slug: params[:slug])
    end
  end
end
