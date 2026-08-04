module Alembic
  class DefinitionLoader
    def initialize(definition)
      @definition = definition
    end

    OPTIONAL_COPY_KEYS = %w[headline kicker blurb start_label].freeze
    RESOLVERS = { "stats_ladder" => StatsLadderPlacement }.freeze

    def build
      Guide.new(slug: @definition["slug"], questions: questions, resolver: resolver, tiers: tiers, levels: levels, warnings: warnings, **optional_copy)
    end

    private

    def resolver
      RESOLVERS[@definition.dig("placement", "resolver_key")]&.new
    end

    def tiers
      Hash(@definition["tiers"]).to_h do |key, node|
        [ key.to_i, node_from(node, id: key.to_i) ]
      end
    end

    def levels
      Hash(@definition["levels"]).to_h do |key, node|
        [ key.to_sym, node_from(node, id: key.to_sym) ]
      end
    end

    NODE_TEXT_KEYS = %w[tagline complexity setup maintenance captures why pains avoid avoid_pain].freeze

    def node_from(node, id:)
      Guide::Node.new(id: id, name: node["name"], build_steps: build_steps_for(node), **node.slice(*NODE_TEXT_KEYS).transform_keys(&:to_sym))
    end

    def build_steps_for(node)
      Array(node["build_steps"]).map do |step|
        Guide::BuildStep.new(title: step["title"], code: step["code"])
      end
    end

    def warnings
      Hash(@definition["warnings"]).transform_keys(&:to_sym)
    end

    def questions
      Array(@definition["questions"]).map do |question|
        Guide::Question.new(id: question["id"].to_sym, text: question["text"], options: options_for(question), condition: condition_for(question))
      end
    end

    def condition_for(question)
      condition = question["condition"]
      return nil unless condition

      answer_key = condition["answer"].to_sym
      return ->(answers) { condition["in"].include?(answers[answer_key]) } if condition.key?("in")

      ->(answers) { answers[answer_key] == condition["equals"] }
    end

    def options_for(question)
      Array(question["options"]).map do |option|
        Guide::Option.new(value: option["value"], label: option["label"], hint: option["hint"], weight: option["weight"])
      end
    end

    def optional_copy
      @definition.slice(*OPTIONAL_COPY_KEYS).transform_keys(&:to_sym)
    end
  end
end
