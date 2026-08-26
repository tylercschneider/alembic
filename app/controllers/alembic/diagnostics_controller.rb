module Alembic
  class DiagnosticsController < ApplicationController
    def show
      @diagnostic = admit(Diagnostic.find_by(slug: params[:slug]))
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

    def render_completion
      @answered = @guide.answers_on_path(@answers)
      @outputs = summarising_diagnostic&.summary_of(@answered.transform_keys(&:to_s)).to_a
      render :complete
    end

    def summarising_diagnostic
      @stored_diagnostic if @stored_diagnostic&.summarises?
    end

    def runner
      @stored_diagnostic = admit(Diagnostic.find_by(slug: params[:slug]))
      @stored_diagnostic.runner
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
