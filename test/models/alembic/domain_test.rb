require "test_helper"

module Alembic
  class DomainTest < ActiveSupport::TestCase
    test "belongs to a diagnostic" do
      diagnostic = Diagnostic.create!(slug: "demo")

      domain = diagnostic.domains.create!(key: "governance", name: "Governance")

      assert_equal diagnostic, domain.diagnostic
    end
  end
end
