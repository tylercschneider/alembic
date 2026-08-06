module Alembic
  class DiagnosticsController < ApplicationController
    def show
      @guide = guide
      return render :guide if @guide

      @diagnostic = Diagnostic.find_by!(slug: params[:slug])
    end

    def step
      @guide = guide
      raise ActiveRecord::RecordNotFound unless @guide

      @answers = submitted_answers
      @answers = without_last_answer(@answers) if params[:back]
      @question = @guide.next_question(@answers)
      return render :step if @question

      return render_result if @guide.bands.any?

      @placement = @guide.place(@answers)
      render :placement
    end

    private

    def render_result
      @score = @guide.score(@answers)
      @band = @guide.result_for(@answers)
      @overall_percentage = @guide.overall_percentage(@answers) if @guide.domains.any?
      render :result
    end

    def guide
      defined_guide || Alembic::Guide.find(params[:slug])
    end

    def defined_guide
      diagnostic = Diagnostic.find_by(slug: params[:slug])
      diagnostic.to_guide if diagnostic&.definition.present?
    end

    def submitted_answers
      params.fetch(:answers, {}).permit(*@guide.questions.map(&:id)).to_h.symbolize_keys
    end

    def without_last_answer(answers)
      last = @guide.applicable_questions(answers).select { |question| answers.key?(question.id) }.last
      last ? answers.except(last.id) : answers
    end
  end
end
