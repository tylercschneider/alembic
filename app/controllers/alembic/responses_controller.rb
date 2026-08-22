module Alembic
  class ResponsesController < ApplicationController
    def create
      redirect_to response_path(Response.start(diagnostic))
    end

    def show
      @response = Response.find(params[:id])
      @guide = @response.guide
      @question = @guide.next_question(@response.answers)
      render :step
    end

    private

    def diagnostic
      Diagnostic.find_by!(slug: params[:slug])
    end
  end
end
