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

    test "a visitor can reach a diagnostic the host authorizes" do
      get alembic.diagnostic_path(published.slug)

      assert_response :success
    end

    test "a visitor cannot reach a diagnostic with nothing published even when the host authorizes it" do
      unpublished = Diagnostic.create!(slug: "unpublished")

      get alembic.diagnostic_path(unpublished.slug)

      assert_response :not_found
    end

    test "a visitor cannot step through a diagnostic the host has not authorized" do
      without_host_configuration do
        get alembic.diagnostic_step_path(published.slug)

        assert_response :not_found
      end
    end

    test "a visitor cannot start a saved session on a diagnostic the host has not authorized" do
      without_host_configuration do
        post alembic.diagnostic_responses_path(published.slug)

        assert_response :not_found
      end
    end

    test "a visitor cannot resume a saved session on a diagnostic the host has not authorized" do
      response = Flow::Run.start(published)

      without_host_configuration do
        get alembic.response_path(response)

        assert_response :not_found
      end
    end

    test "a visitor cannot answer into a saved session on a diagnostic the host has not authorized" do
      response = Flow::Run.start(published)

      without_host_configuration do
        patch alembic.response_path(response), params: { answers: { ask: "yes" } }

        assert_response :not_found
      end
    end

    test "an admin can preview a diagnostic a visitor cannot reach" do
      without_host_configuration do
        get alembic.manage_diagnostic_preview_path(published)

        assert_response :success
      end
    end

    test "an admin can step through a preview a visitor cannot reach" do
      without_host_configuration do
        get alembic.step_manage_diagnostic_preview_path(published)

        assert_response :success
      end
    end

    test "a preview starts into the preview rather than the visitor path" do
      without_host_configuration do
        get alembic.manage_diagnostic_preview_path(published)

        assert_select "a[href=?]", alembic.step_manage_diagnostic_preview_path(published)
      end
    end

    test "a host can answer a refusal its own way instead of the plain not found" do
      Alembic.refusal_method = :send_a_refused_visitor_to_login

      without_host_configuration do
        get alembic.diagnostic_path(published.slug)

        assert_redirected_to "/host-login"
      end
    ensure
      Alembic.refusal_method = nil
    end

    test "a host is told which refusal it is answering" do
      Alembic.refusal_method = :note_the_refusal

      without_host_configuration do
        get alembic.diagnostic_path(published.slug)

        assert_equal "Alembic::NotPermitted", response.headers["X-Refusal"]
      end
    ensure
      Alembic.refusal_method = nil
    end
  end
end
