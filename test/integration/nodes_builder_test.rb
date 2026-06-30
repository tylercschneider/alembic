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

    test "the nodes index links each node to its edit form" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)

      get alembic.manage_diagnostic_nodes_path(diagnostic)

      assert_select "a[href=?]", alembic.edit_manage_diagnostic_node_path(diagnostic, node)
    end

    test "updating a node saves a build step change" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)
      step = node.build_steps.create!(title: "Index", code: "old", position: 1)

      patch alembic.manage_diagnostic_node_path(diagnostic, node), params: { node: { build_steps_attributes: [ { id: step.id, code: "new" } ] } }

      assert_equal "new", step.reload.code
    end

    test "the node edit form renders a code field for each build step" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)
      node.build_steps.create!(title: "Index", code: "add_index :contacts, :status", position: 1)

      get alembic.edit_manage_diagnostic_node_path(diagnostic, node)

      assert_select "textarea[name=?]", "node[build_steps_attributes][0][code]", text: "add_index :contacts, :status"
    end

    test "the node edit form renders a remove checkbox for each build step" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)
      node.build_steps.create!(title: "Index", code: "x", position: 1)

      get alembic.edit_manage_diagnostic_node_path(diagnostic, node)

      assert_select "input[type=checkbox][name=?]", "node[build_steps_attributes][0][_destroy]"
    end

    test "updating a node with _destroy removes the build step" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)
      step = node.build_steps.create!(title: "Index", code: "x", position: 1)

      assert_difference -> { node.build_steps.count }, -1 do
        patch alembic.manage_diagnostic_node_path(diagnostic, node), params: { node: { build_steps_attributes: [ { id: step.id, _destroy: "1" } ] } }
      end
    end

    test "adding a build step creates one on the node" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)

      assert_difference -> { node.build_steps.count } do
        post alembic.manage_diagnostic_node_build_steps_path(diagnostic, node)
      end
    end

    test "the node edit form has an add-build-step button" do
      diagnostic = Diagnostic.create!(slug: "nodes")
      node = diagnostic.nodes.create!(kind: "tier", key: "1", name: "Live query", position: 1)

      get alembic.edit_manage_diagnostic_node_path(diagnostic, node)

      assert_select "form[action=?]", alembic.manage_diagnostic_node_build_steps_path(diagnostic, node)
    end
  end
end
