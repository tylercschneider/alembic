require "test_helper"

module Alembic
  class RuleTest < ActiveSupport::TestCase
    test "a rule with no conditions fires for any answers" do
      diagnostic = Diagnostic.create!(slug: "rule-fires", kind: :guide, status: :draft)
      rule = diagnostic.rules.create!(position: 1)

      assert rule.fires?({})
    end

    test "a rule does not fire when one of its conditions is unmet" do
      diagnostic = alembic_diagnostics(:stats_ladder)
      rule = diagnostic.rules.create!(position: 1)
      rule.conditions.create!(tested_question: alembic_questions(:ladder_need), options: [ alembic_options(:need_now) ])

      assert_not rule.fires?({ "need" => "trend" })
    end
  end
end
