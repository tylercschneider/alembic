require "test_helper"

module Alembic
  class DefinitionLoaderTest < ActiveSupport::TestCase
    test "builds a guide carrying the definition's slug" do
      loader = DefinitionLoader.new({ "slug" => "demo" })

      assert_equal "demo", loader.build.slug
    end

    test "builds a guide carrying the definition's headline" do
      loader = DefinitionLoader.new({ "headline" => "Where to?" })

      assert_equal "Where to?", loader.build.headline
    end

    test "builds a guide carrying the definition's kicker" do
      loader = DefinitionLoader.new({ "kicker" => "Diagnose · Place" })

      assert_equal "Diagnose · Place", loader.build.kicker
    end

    test "builds a guide carrying the definition's blurb" do
      loader = DefinitionLoader.new({ "blurb" => "Answer a few questions." })

      assert_equal "Answer a few questions.", loader.build.blurb
    end

    test "builds a guide carrying the definition's start label" do
      loader = DefinitionLoader.new({ "start_label" => "Start the quiz →" })

      assert_equal "Start the quiz →", loader.build.start_label
    end

    test "builds a question carrying its id as a symbol" do
      loader = DefinitionLoader.new({ "questions" => [ { "id" => "need", "text" => "Need?" } ] })

      assert_equal :need, loader.build.questions.first.id
    end
  end
end
