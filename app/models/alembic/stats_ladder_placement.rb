module Alembic
  class StatsLadderPlacement
    TIER_BY_NEED = { "now" => 1, "trend" => 3, "rates" => 4, "audit" => 5 }.freeze
    LOSSY_LEVELS = [ :l12, :l0 ].freeze

    def call(answers)
      tier = tier_for(answers)
      return below_events(tier) if tier < 4
      return event_sourcing(tier, answers) if tier == 5

      with_events(tier, answers)
    end

    private

    def event_sourcing(tier, answers)
      level = durable_floor(level_for(tier, :money, answers))
      Guide::Placement.new(tier: tier, grade: :money, level: level, warning: :sourcing_floor, warning_ok: false)
    end

    def durable_floor(level)
      LOSSY_LEVELS.include?(level) ? :l3 : level
    end

    def below_events(tier)
      Guide::Placement.new(tier: tier, grade: nil, level: nil, warning: nil, warning_ok: false)
    end

    def with_events(tier, answers)
      grade = grade_for(answers)
      return money_on_lossy(tier) if grade == :money && answers[:origin] == "anon"

      level = level_for(tier, grade, answers)
      Guide::Placement.new(tier: tier, grade: grade, level: level, warning: pairing_for(grade), warning_ok: true)
    end

    def money_on_lossy(tier)
      Guide::Placement.new(tier: tier, grade: :money, level: :l3, warning: :money_vs_lossy, warning_ok: false)
    end

    def pairing_for(grade)
      (grade == :money) ? :money_pairing : :insight_pairing
    end

    def grade_for(answers)
      (answers[:loss] == "money") ? :money : :insight
    end

    def level_for(tier, grade, answers)
      case answers[:origin]
      when "anon" then :l0
      when "svc" then :l4
      else (grade == :money || tier == 5) ? :l3 : :l12
      end
    end

    def tier_for(answers)
      base = TIER_BY_NEED.fetch(answers[:need], 1)
      (base == 1 && answers[:read] == "hot") ? 2 : base
    end
  end
end
