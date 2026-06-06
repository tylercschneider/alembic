require "test_helper"

module Alembic
  class BuildStepTest < ActiveSupport::TestCase
    test "belongs to a node and stores its code" do
      diagnostic = Diagnostic.create!(slug: "with-steps")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query")
      step = node.build_steps.create!(title: "Index", code: "add_index :contacts, :status")

      assert_equal "add_index :contacts, :status", step.code
    end
  end
end
