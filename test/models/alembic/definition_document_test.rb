require "test_helper"

module Alembic
  class DefinitionDocumentTest < ActiveSupport::TestCase
    test "reordering keeps a question the given order leaves out" do
      document = DefinitionDocument.new({ "questions" => [ { "id" => "a" }, { "id" => "b" } ] })

      assert_equal [ "b", "a" ], document.reorder([ "b" ])["questions"].map { |question| question["id"] }
    end

    test "reordering puts the questions in the order given" do
      document = DefinitionDocument.new({ "questions" => [ { "id" => "a" }, { "id" => "b" } ] })

      assert_equal [ "b", "a" ], document.reorder([ "b", "a" ])["questions"].map { |question| question["id"] }
    end
  end
end
