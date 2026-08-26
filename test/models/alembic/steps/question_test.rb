require "test_helper"

module Alembic
  module Steps
    class QuestionTest < ActiveSupport::TestCase
      test "declares a setting for the question it asks" do
        assert_equal :string, Question.step_type.fields[:question]
      end

      test "declares a setting for the readable name it is shown by" do
        assert_equal :string, Question.step_type.fields[:name]
      end

      test "declares a setting for the answers it offers" do
        assert_equal :list, Question.step_type.fields[:answers]
      end

      test "an answer carries the weight the summary scores it by" do
        assert_equal :integer, Question.step_type.record_fields[:answers][:weight]
      end

      test "declares a category the summary can group it by" do
        assert_equal :string, Question.step_type.fields[:category]
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

        assert_equal "Question", registry.fetch(node.type).step_name
      end

      test "awaits external input" do
        assert_predicate Question.step_type, :awaits_input?
      end
    end
  end
end
