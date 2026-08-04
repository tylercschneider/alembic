require "test_helper"

module Alembic
  class NodeTest < ActiveSupport::TestCase
    test "belongs to a diagnostic and stores its name" do
      diagnostic = Diagnostic.create!(slug: "with-nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query")

      assert_equal "Live query", node.name
    end

    test "moving a node down places it after its neighbour" do
      diagnostic = Diagnostic.create!(slug: "node-move")
      first = diagnostic.nodes.create!(kind: "tier", key: "a", position: 1)
      diagnostic.nodes.create!(kind: "tier", key: "b", position: 2)

      first.move_down

      assert_equal [ "b", "a" ], diagnostic.nodes.ordered.map(&:key)
    end

    test "updates a build step through nested attributes" do
      diagnostic = Diagnostic.create!(slug: "with-nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query")
      step = node.build_steps.create!(title: "Index", code: "old")

      node.update!(build_steps_attributes: [ { id: step.id, code: "new" } ])

      assert_equal "new", step.reload.code
    end
  end
end
