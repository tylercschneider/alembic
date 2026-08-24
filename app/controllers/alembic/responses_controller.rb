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
      return render_completion unless @guide.scored?

      render_result
    end

    def update
      response = Response.find(params[:id])
      params[:back] ? response.discard_last_answer : record_submitted_answer(response)
      redirect_to response_path(response)
    end

    private

    def render_completion
      @answered = @guide.answers_on_path(@answers)
      render template: "alembic/diagnostics/complete"
    end

    def render_result
      @score = @guide.score(@answers)
      @band = @guide.result_for(@answers)
      @summary = @guide.summary(@answers)
      render template: "alembic/diagnostics/result"
    end

    def record_submitted_answer(response)
      question_id, value = params.fetch(:answers, {}).permit(*response.guide.questions.map(&:id)).to_h.first
      response.record_answer(question_id.to_sym, value)
    end

    def diagnostic
      Diagnostic.find_by!(slug: params[:slug])
    end
  end
end
