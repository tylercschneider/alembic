require "test_helper"

module Alembic
  class NodesBuilderTest < ActionDispatch::IntegrationTest
    test "the nodes index lists the diagnostic's nodes" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)

      get alembic.manage_diagnostic_nodes_path(diagnostic)

      assert_includes response.body, "Live query"
    end
  end
end
