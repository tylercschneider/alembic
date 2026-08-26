require "test_helper"

module Alembic
  class AdmissionTest < ActiveSupport::TestCase
    def published
      alembic_diagnostics(:db_guide)
    end

    test "it refuses a diagnostic with nothing published as unpublished" do
      unpublished = Diagnostic.create!(slug: "nothing-published")

      assert_raises(NotPublished) { Admission.of(unpublished, permitted: true) }
    end

    test "it refuses a visitor the host declined as not permitted" do
      assert_raises(NotPermitted) { Admission.of(published, permitted: false) }
    end

    test "it returns the diagnostic when it is published and permitted" do
      assert_equal published, Admission.of(published, permitted: true)
    end
  end
end
