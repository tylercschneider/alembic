require "test_helper"

module Alembic
  class NodesBuilderTest < ActionDispatch::IntegrationTest
    test "the nodes index lists the diagnostic's nodes" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)

      get alembic.manage_diagnostic_nodes_path(diagnostic)

      assert_includes response.body, "Live query"
    end

    test "the hub links to the nodes editor" do
      diagnostic = alembic_diagnostics(:stats_ladder)

      get alembic.manage_diagnostic_path(diagnostic)

      assert_select "a[href=?]", alembic.manage_diagnostic_nodes_path(diagnostic)
    end

    test "the node edit form prefills the node name" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)

      get alembic.edit_manage_diagnostic_node_path(diagnostic, node)

      assert_select "input[name=?][value=?]", "node[name]", "Live query"
    end
  end
end
