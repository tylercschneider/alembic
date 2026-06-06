require "test_helper"

module Alembic
  class WarningTest < ActiveSupport::TestCase
    test "belongs to a diagnostic and stores its text" do
      diagnostic = Diagnostic.create!(slug: "with-warnings")
      warning = diagnostic.warnings.create!(key: "money_pairing", text: "Good pairing.")

      assert_equal "Good pairing.", warning.text
    end
  end
end
