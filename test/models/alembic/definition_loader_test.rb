require "test_helper"

module Alembic
  class DefinitionLoaderTest < ActiveSupport::TestCase
    test "builds a guide carrying the definition's slug" do
      loader = DefinitionLoader.new({ "slug" => "demo" })

      assert_equal "demo", loader.build.slug
    end
  end
end
