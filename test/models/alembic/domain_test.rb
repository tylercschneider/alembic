require "test_helper"

module Alembic
  class DomainTest < ActiveSupport::TestCase
    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")

      domain = diagnostic.domains.create!(key: "governance", name: "Governance")

      assert_equal diagnostic, domain.diagnostic
    end

    test "has many questions" do
      diagnostic = Diagnostic.create!(slug: "demo")
      domain = diagnostic.domains.create!(key: "governance", name: "Governance")

      question = diagnostic.questions.create!(key: "need", text: "Need?", position: 1, domain: domain)

      assert_equal [ question ], domain.questions.to_a
    end
  end
end
