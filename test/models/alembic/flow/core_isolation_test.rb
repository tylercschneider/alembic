require "test_helper"

module Alembic
  module Flow
    class CoreIsolationTest < ActiveSupport::TestCase
      def core_sources
        Dir[Engine.root.join("app/models/alembic/flow.rb")] +
          Dir[Engine.root.join("app/models/alembic/flow/**/*.rb")]
      end

      def step_type_names
        Dir[Engine.root.join("app/models/alembic/steps/*.rb")].map { |source| File.basename(source, ".rb") }
      end

      def gem_sources
        Dir[Engine.root.join("app/**/*.rb")] + Dir[Engine.root.join("lib/**/*.rb")]
      end

      test "there are flow core sources to check" do
        assert_not_empty core_sources
      end

      test "there are step types to check the core against" do
        assert_not_empty step_type_names
      end

      test "the flow core names no step type the gem defines" do
        naming_one = core_sources.select do |source|
          body = File.read(source)
          step_type_names.any? { |name| body.match?(/#{name}/i) }
        end

        assert_empty naming_one.map { |source| source.split("/models/").last }
      end

      test "nothing in the gem registers a step type at load time" do
        registering = gem_sources.select { |source| File.read(source).match?(/[A-Z]\w*\.register\b/) }

        assert_empty registering.map { |source| source.split("/alembic/").last }
      end
    end
  end
end
