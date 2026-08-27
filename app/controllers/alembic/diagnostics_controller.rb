module Alembic
  class DiagnosticsController < ApplicationController
    helper_method :flow_start_path, :flow_step_path, :previewing?

    def show
      @diagnostic = admit(Flow::Flow.find_by(slug: params[:slug]))
    end

    def step
      @guide = runner
      @answers = submitted_answers
      @answers = without_last_answer(@answers) if params[:back]
      @question = @guide.next_question(@answers)
      return render :step if @question

      render_completion
    end

    private

    def flow_start_path(slug)
      alembic.diagnostic_path(slug)
    end

    def flow_step_path(slug)
      alembic.diagnostic_step_path(slug)
    end

    def previewing?
      false
    end

    def render_completion
      @answered = @guide.answers_on_path(@answers)
      @outputs = summarising_diagnostic&.summary_of(@answered.transform_keys(&:to_s)).to_a
      render :complete
    end

    def summarising_diagnostic
      @stored_diagnostic if @stored_diagnostic&.summarises?
    end

    def runner
      @stored_diagnostic = admit(Flow::Flow.find_by(slug: params[:slug]))
      Runner.new(flowing_definition(@stored_diagnostic))
    end

    def flowing_definition(diagnostic)
      diagnostic.live_definition
    end

    def submitted_answers
      params.fetch(:answers, {}).permit(*@guide.questions.map(&:id)).to_h.symbolize_keys
    end

    def without_last_answer(answers)
      last = @guide.answers_on_path(answers).keys.last

      last ? answers.except(last) : answers
    end
  end
end
