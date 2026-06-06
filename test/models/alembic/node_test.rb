require "test_helper"

module Alembic
  class NodeTest < ActiveSupport::TestCase
    test "belongs to a diagnostic and stores its name" do
      diagnostic = Diagnostic.create!(slug: "with-nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query")

      assert_equal "Live query", node.name
    end
  end
end
