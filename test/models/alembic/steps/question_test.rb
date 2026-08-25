require "test_helper"

module Alembic
  module Steps
    class QuestionTest < ActiveSupport::TestCase
      test "declares a field for the text it asks" do
        assert_equal :string, Question.step_type.fields[:text]
      end

      test "declares a field for the options it offers" do
        assert_equal :records, Question.step_type.fields[:options]
      end

      test "an option carries the weight the summary scores it by" do
        assert_equal :integer, Question.step_type.record_fields[:options][:weight]
      end

      test "declares a tag the summary can group it by" do
        assert_equal :string, Question.step_type.fields[:tag]
      end

      test "has a single unnamed output" do
        assert_predicate Question.step_type, :single_output?
      end

      test "registers through the public step-type API" do
        registry = Flow::Registry.new

        Question.register(registry)

        assert_equal :question, registry.fetch("question").id
      end

      test "resolves for a document node naming it as the type" do
        registry = Flow::Registry.new
        Question.register(registry)
        node = Flow::Document.new({ "nodes" => [ { "id" => "q", "type" => "question" } ] }).node("q")

        assert_equal "Question", registry.fetch(node.type).label
      end

      test "awaits external input" do
        assert_predicate Question.step_type, :awaits_input?
      end
    end
  end
end
