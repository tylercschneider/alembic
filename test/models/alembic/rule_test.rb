require "test_helper"

module Alembic
  class RuleTest < ActiveSupport::TestCase
    test "a rule with no conditions fires for any answers" do
      diagnostic = Diagnostic.create!(slug: "rule-fires", kind: :guide, status: :draft)
      rule = diagnostic.rules.create!(position: 1)

      assert rule.fires?({})
    end
  end
end
