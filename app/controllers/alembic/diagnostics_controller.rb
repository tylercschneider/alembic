module Alembic
  class DiagnosticsController < ApplicationController
    BLIND_SPOT_COUNT = 2

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
      @summary = @guide.summary(@answers)
      assign_domain_figures if @guide.domains.any?
      render :result
    end

    def assign_domain_figures
      @overall_percentage = @guide.overall_percentage(@answers)
      @domain_percentages = @guide.domain_percentages(@answers).transform_keys { |key| @guide.domains[key] }
      @blind_spots = @guide.blind_spots(@answers, count: BLIND_SPOT_COUNT).map { |key| @guide.domains[key] }
    end

    def guide
      defined_guide || Alembic::Guide.find(params[:slug])
    end

    def defined_guide
      diagnostic = Diagnostic.find_by(slug: params[:slug])
      return if diagnostic&.definition.blank?

      @stored_diagnostic = diagnostic
      diagnostic.to_guide
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
