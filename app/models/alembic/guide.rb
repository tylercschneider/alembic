module Alembic
  class Guide
    Option = Data.define(:value, :label, :hint, :weight) do
      def initialize(value:, label:, hint:, weight: nil)
        super
      end
    end

    Question = Data.define(:id, :text, :options, :condition, :domain) do
      def initialize(id:, text:, options: [], condition: nil, domain: nil)
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

    Domain = Data.define(:key, :name, :gap_meaning, :gap_cost)

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

    attr_reader :slug, :questions, :resolver, :kicker, :headline, :blurb, :start_label, :tiers, :levels, :warnings, :bands, :domains

    def initialize(slug:, questions:, resolver: nil, kicker: nil, headline: nil, blurb: nil, start_label: "Start →", tiers: {}, levels: {}, warnings: {}, bands: [], domains: {})
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
      @domains = domains
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

    def overall_percentage(answers)
      percentage_of(questions, answers)
    end

    def domain_percentages(answers)
      domains.keys.index_with { |key| percentage_of(questions_in(key), answers) }
    end

    def blind_spots(answers, count:)
      domain_percentages(answers).min_by(count) { |_key, percentage| percentage }.map(&:first)
    end

    def result_for(answers)
      band_for(domains.any? ? overall_percentage(answers) : score(answers))
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

    private

    def questions_in(domain_key)
      questions.select { |question| question.domain == domain_key }
    end

    def percentage_of(questions, answers)
      on_offer = weight_on_offer(questions)
      return 0 if on_offer.zero?

      (captured_weight(questions, answers).to_f / on_offer * 100).round
    end

    def captured_weight(questions, answers)
      questions.sum { |question| weight_of(question, answers[question.id]) }
    end

    def weight_on_offer(questions)
      questions.sum { |question| question.options.filter_map(&:weight).max || 0 }
    end

    def weight_of(question, value)
      question.options.find { |option| option.value == value }&.weight || 0
    end
  end
end
