require "test_helper"

module Alembic
  class VisitorGateTest < ActionDispatch::IntegrationTest
    def published
      @published ||= Diagnostic.create!(slug: "gated").tap do |diagnostic|
        diagnostic.record_definition(
          "slug" => "gated", "entry" => "ask",
          "nodes" => [ { "id" => "ask", "type" => "question", "text" => "Ready?",
                         "options" => [ { "value" => "yes", "weight" => 1 } ] } ],
          "edges" => []
        )
        diagnostic.publish
      end
    end

    def without_host_configuration
      permission = Alembic.visitor_authorization_method
      Alembic.visitor_authorization_method = nil
      yield
    ensure
      Alembic.visitor_authorization_method = permission
    end

    test "a visitor cannot reach a diagnostic the host has not authorized" do
      without_host_configuration do
        get alembic.diagnostic_path(published.slug)

        assert_response :not_found
      end
    end
  end
end
