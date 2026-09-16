require "test_helper"

module Alembic
  class PageBuilderTest < ActionDispatch::IntegrationTest
    test "the page list shows each page by name" do
      Page.create!(name: "Welcome")

      get alembic.manage_pages_path

      assert_includes response.body, "Welcome"
    end

    test "creating a page saves it by name" do
      post alembic.manage_pages_path, params: { page: { name: "Welcome" } }

      assert Page.exists?(name: "Welcome")
    end

    test "the page list offers a form to create a page by name" do
      get alembic.manage_pages_path

      assert_select "form[action=?] input[name=?]", alembic.manage_pages_path, "page[name]"
    end

    test "opening a page mounts the page builder" do
      page = Page.create!(name: "Welcome")

      get alembic.manage_page_path(page)

      assert_select "[data-react-ui=?]", "alembic/page-builder"
    end

    test "the page builder is given the page's name" do
      page = Page.create!(name: "Welcome")

      get alembic.manage_page_path(page)

      assert_equal "Welcome", page_builder_props["name"]
    end

    test "the page builder is given the address of its page's endpoints" do
      page = Page.create!(name: "Welcome")

      get alembic.manage_page_path(page)

      assert_equal alembic.manage_page_path(page), page_builder_props["base"]
    end

    test "the page builder screen loads the page builder script" do
      page = Page.create!(name: "Welcome")

      get alembic.manage_page_path(page)

      assert_select "script[src*=?]", "alembic/page_builder"
    end

    test "the page builder is given the page list's address" do
      page = Page.create!(name: "Welcome")

      get alembic.manage_page_path(page)

      assert_equal alembic.manage_pages_path, page_builder_props["pages"]
    end

    test "the page list links each page to its page builder" do
      page = Page.create!(name: "Welcome")

      get alembic.manage_pages_path

      assert_select "a[href=?]", alembic.manage_page_path(page)
    end

    test "creating a page opens it in the page builder" do
      post alembic.manage_pages_path, params: { page: { name: "Welcome" } }

      assert_redirected_to alembic.manage_page_path(Page.find_by!(name: "Welcome"))
    end

    test "the page builder is given each registered block type's key, name and starting size" do
      KsBlocks.block(:payload_probe, name: "Payload probe", width: 6, height: 2, kind: :pages)

      get alembic.manage_page_path(Page.create!(name: "Welcome"))

      listed = page_builder_props["block_types"].find { |block_type| block_type["key"] == "payload_probe" }

      assert_equal({ "key" => "payload_probe", "name" => "Payload probe", "width" => 6, "height" => 2 }, listed.slice("key", "name", "width", "height"))
    end

    test "adding a block puts a block of that type at the given place" do
      page = Page.create!(name: "Welcome")

      post alembic.manage_page_blocks_path(page), params: { type: "heading", x: 0, y: 2 }, as: :json

      assert_equal [ "heading", 0, 2 ], page.reload.blocks.last.values_at("type", "x", "y")
    end

    test "the page builder is given the page's blocks with their positions and sizes" do
      page = Page.create!(name: "Welcome")
      page.add_block(KsBlocks::BlockType.new(key: :text, name: "Text", width: 6, height: 2), x: 3, y: 1)

      get alembic.manage_page_path(page)

      assert_equal page.reload.blocks, page_builder_props["blocks"]
    end

    test "the page's json is what the page builder is mounted with, apart from its token" do
      page = Page.create!(name: "Welcome")
      page.add_block(KsBlocks::BlockType.new(key: :text, name: "Text", width: 6, height: 2), x: 3, y: 1)
      get alembic.manage_page_path(page)
      mounted = page_builder_props.except("token")

      get alembic.manage_page_path(page, format: :json)

      assert_equal mounted, response.parsed_body
    end

    test "the page builder is given a token to send changes with" do
      get alembic.manage_page_path(Page.create!(name: "Welcome"))

      assert page_builder_props["token"].present?
    end

    test "the page builder screen links the page builder stylesheet" do
      get alembic.manage_page_path(Page.create!(name: "Welcome"))

      assert_select "link[rel=stylesheet][href*=?]", "alembic/page_builder"
    end

    test "placing blocks stores the positions they were moved to" do
      page = Page.create!(name: "Welcome")
      page.add_block(KsBlocks::BlockType.new(key: :text, name: "Text", width: 6, height: 2), x: 0, y: 0)

      patch alembic.manage_page_blocks_path(page), params: { layout: [ { id: page.blocks.first["id"], x: 6, y: 2 } ] }, as: :json

      assert_equal [ 6, 2 ], page.reload.blocks.first.values_at("x", "y")
    end

    test "placing blocks stores the sizes they were given" do
      page = Page.create!(name: "Welcome")
      page.add_block(KsBlocks::BlockType.new(key: :text, name: "Text", width: 6, height: 2), x: 0, y: 0)

      patch alembic.manage_page_blocks_path(page), params: { layout: [ { id: page.blocks.first["id"], x: 0, y: 0, w: 9, h: 4 } ] }, as: :json

      assert_equal [ 9, 4 ], page.reload.blocks.first.values_at("w", "h")
    end

    test "removing a block takes it off the page" do
      page = Page.create!(name: "Welcome")
      page.add_block(KsBlocks::BlockType.new(key: :text, name: "Text", width: 6, height: 2), x: 0, y: 0)

      delete alembic.manage_page_block_path(page, page.blocks.first["id"]), as: :json

      assert_empty page.reload.blocks
    end

    test "a page's layout endpoint answers with its block types and blocks" do
      page = Page.create!(name: "Welcome")
      page.add_block(KsBlocks::BlockType.new(key: :text, name: "Text", width: 6, height: 2), x: 0, y: 0)

      get alembic.manage_page_layout_path(page), as: :json

      assert_equal page.reload.blocks, response.parsed_body["blocks"]
    end

    private

    def page_builder_props
      JSON.parse(css_select("[data-react-ui='alembic/page-builder']").first["data-props"])
    end
  end
end
