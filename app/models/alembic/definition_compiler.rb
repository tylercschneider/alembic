module Alembic
  class DefinitionCompiler
    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def to_definition
      {
        "slug" => @diagnostic.slug,
        "kicker" => @diagnostic.kicker,
        "headline" => @diagnostic.headline,
        "blurb" => @diagnostic.blurb,
        "start_label" => @diagnostic.start_label,
        "placement" => { "resolver_key" => @diagnostic.resolver_key },
        "questions" => compile_questions,
        "tiers" => compile_nodes("tier"),
        "levels" => compile_nodes("level"),
        "warnings" => compile_warnings
      }
    end

    private

    NODE_TEXT_KEYS = %w[tagline complexity setup maintenance captures why pains avoid avoid_pain].freeze

    def compile_nodes(kind)
      @diagnostic.nodes.where(kind: kind).order(:position).to_h do |node|
        [ node.key, compile_node(node) ]
      end
    end

    def compile_node(node)
      body = { "name" => node.name }.merge(node_text(node))
      steps = compile_steps(node)
      steps.any? ? body.merge("build_steps" => steps) : body
    end

    def compile_steps(node)
      node.build_steps.order(:position).map do |step|
        { "title" => step.title, "code" => step.code }
      end
    end

    def compile_warnings
      @diagnostic.warnings.to_h { |warning| [ warning.key, warning.text ] }
    end

    def node_text(node)
      NODE_TEXT_KEYS.each_with_object({}) do |key, text|
        value = node.public_send(key)
        text[key] = value unless value.nil?
      end
    end

    def compile_questions
      @diagnostic.questions.ordered.map do |question|
        base = { "id" => question.key, "text" => question.text, "options" => compile_options(question) }
        condition = compile_condition(question)
        condition ? base.merge("condition" => condition) : base
      end
    end

    def compile_condition(question)
      condition = question.conditions.first
      return nil unless condition

      values = condition.options.ordered.map(&:value)
      answer = { "answer" => condition.tested_question.key }
      values.one? ? answer.merge("equals" => values.first) : answer.merge("in" => values)
    end

    def compile_options(question)
      question.options.ordered.map do |option|
        base = { "value" => option.value, "label" => option.label, "hint" => option.hint }
        option.weight.nil? ? base : base.merge("weight" => option.weight)
      end
    end
  end
end
