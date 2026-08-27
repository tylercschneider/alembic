module Alembic
  class ResponsesController < ApplicationController
    def create
      redirect_to response_path(Flow::Run.start(diagnostic))
    end

    def show
      @response = saved_session
      @guide = @response.guide
      @answers = @response.answers
      @question = @guide.next_question(@answers)
      return render :step if @question

      render_completion
    end

    def update
      response = saved_session
      params[:back] ? response.discard_last_answer : record_submitted_answer(response)
      redirect_to response_path(response)
    end

    private

    def render_completion
      @answered = @guide.answers_on_path(@answers)
      @outputs = @response.summary_of(@answered.transform_keys(&:to_s))
      render template: "alembic/diagnostics/complete"
    end

    def record_submitted_answer(response)
      question_id, value = params.fetch(:answers, {}).permit(*response.guide.questions.map(&:id)).to_h.first
      response.record_answer(question_id.to_sym, value)
    end

    def saved_session
      run = Flow::Run.find(params[:id])

      Admission.of_run(run, permitted: permitted?(run.flow))
    end

    def diagnostic
      admit(Diagnostic.find_by(slug: params[:slug]))
    end
  end
end
