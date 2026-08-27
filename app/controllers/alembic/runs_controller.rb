module Alembic
  class RunsController < ApplicationController
    def create
      redirect_to run_path(Flow::Run.start(diagnostic))
    end

    def show
      @response = saved_session
      @guide = Runner.new(@response.pinned_definition)
      @answers = @response.recorded
      @question = @guide.next_question(@answers)
      return render :step if @question

      render_completion
    end

    def update
      response = saved_session
      params[:back] ? response.discard_last : record_submitted_answer(response)
      redirect_to run_path(response)
    end

    private

    def render_completion
      @answered = @guide.answers_on_path(@answers)
      @outputs = summarised(@answered.transform_keys(&:to_s))
      render template: "alembic/flows/complete"
    end

    def summarised(state)
      return [] if @response.pinned_summary.blank?

      Summary::Report.new(@response.pinned_summary)
        .results(Summary::Run.new(state: state, steps: @response.pinned_steps))
    end

    def record_submitted_answer(response)
      asked = Runner.new(response.pinned_definition).questions.map(&:id)
      question_id, value = params.fetch(:answers, {}).permit(*asked).to_h.first
      response.record(question_id.to_sym, value)
    end

    def saved_session
      run = Flow::Run.find(params[:id])

      Admission.of_run(run, permitted: permitted?(run.flow))
    end

    def diagnostic
      admit(Flow::Definition.find_by(slug: params[:slug]))
    end
  end
end
