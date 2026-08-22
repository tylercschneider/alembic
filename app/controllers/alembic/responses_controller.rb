module Alembic
  class ResponsesController < ApplicationController
    def create
      redirect_to response_path(Response.start(diagnostic))
    end

    def show
      @response = Response.find(params[:id])
      @guide = @response.guide
      @answers = @response.answers
      @question = @guide.next_question(@answers)
      return render :step if @question

      render_result
    end

    def update
      response = Response.find(params[:id])
      question_id, value = submitted_answer(response.guide)
      response.record_answer(question_id.to_sym, value)
      redirect_to response_path(response)
    end

    private

    def render_result
      @score = @guide.score(@answers)
      @band = @guide.result_for(@answers)
      render template: "alembic/diagnostics/result"
    end

    def submitted_answer(guide)
      params.fetch(:answers, {}).permit(*guide.questions.map(&:id)).to_h.first
    end

    def diagnostic
      Diagnostic.find_by!(slug: params[:slug])
    end
  end
end
