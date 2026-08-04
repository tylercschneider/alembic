require "test_helper"

module Alembic
  class BuildStepTest < ActiveSupport::TestCase
    test "belongs to a node and stores its code" do
      diagnostic = Diagnostic.create!(slug: "with-steps")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query")
      step = node.build_steps.create!(title: "Index", code: "add_index :contacts, :status")

      assert_equal "add_index :contacts, :status", step.code
    end

    test "moving a build step down places it after its neighbour" do
      node = Diagnostic.create!(slug: "step-move").nodes.create!(kind: "tier", key: "1")
      first = node.build_steps.create!(title: "a", position: 1)
      node.build_steps.create!(title: "b", position: 2)

      first.move_down

      assert_equal [ "b", "a" ], node.build_steps.ordered.map(&:title)
    end
  end
end
