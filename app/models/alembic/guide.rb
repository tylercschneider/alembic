module Alembic
  class Guide
    Option = Data.define(:value, :label, :hint, :weight) do
      def initialize(value:, label:, hint:, weight: nil)
        super
      end
    end

    Question = Data.define(:id, :text, :options, :condition) do
      def initialize(id:, text:, options: [], condition: nil)
        super
      end

      def applies?(answers)
        condition.nil? || condition.call(answers)
      end
    end

    Band = Data.define(:ceiling, :name, :description) do
      def initialize(ceiling:, name:, description: nil)
        super
      end
    end

    Placement = Data.define(:tier, :grade, :level, :warning, :warning_ok)

    BuildStep = Data.define(:title, :code)
    Resource = Data.define(:kind, :label, :sublabel, :href) do
      def initialize(kind:, label:, href:, sublabel: nil)
        super
      end
    end

    Node = Data.define(:id, :name, :tagline, :complexity, :setup, :maintenance, :captures, :why, :pains, :avoid, :avoid_pain, :build_steps, :resources) do
      def initialize(id:, name:, tagline: nil, complexity: nil, setup: nil, maintenance: nil, captures: nil, why: nil, pains: nil, avoid: nil, avoid_pain: nil, build_steps: [], resources: [])
        super
      end
    end

    attr_reader :slug, :questions, :resolver, :kicker, :headline, :blurb, :start_label, :tiers, :levels, :warnings, :bands

    def initialize(slug:, questions:, resolver: nil, kicker: nil, headline: nil, blurb: nil, start_label: "Start →", tiers: {}, levels: {}, warnings: {}, bands: [])
      @slug = slug
      @questions = questions
      @resolver = resolver
      @kicker = kicker
      @headline = headline
      @blurb = blurb
      @start_label = start_label
      @tiers = tiers
      @levels = levels
      @warnings = warnings
      @bands = bands
    end

    def warning_text(key)
      warnings[key]
    end

    def tier(number)
      tiers[number]
    end

    def level(key)
      levels[key]
    end

    def score(answers)
      answers.sum do |question_id, value|
        question = questions.find { |candidate| candidate.id == question_id }
        option = question&.options&.find { |candidate| candidate.value == value }
        option&.weight || 0
      end
    end

    def band_for(score)
      bands.sort_by { |band| band.ceiling || Float::INFINITY }
        .find { |band| band.ceiling.nil? || score < band.ceiling }
    end

    def place(answers)
      resolver.call(answers)
    end

    def next_question(answers)
      questions.find { |question| question.applies?(answers) && !answers.key?(question.id) }
    end

    def applicable_questions(answers)
      questions.select { |question| question.applies?(answers) }
    end

    def complete?(answers)
      next_question(answers).nil?
    end

    GUIDES = [ StatsSystemLadder ].freeze

    def self.find(slug)
      registry[slug]
    end

    def self.all
      registry.values
    end

    def self.registry
      @registry ||= GUIDES.map(&:build).to_h { |guide| [ guide.slug, guide ] }
    end
  end
end
