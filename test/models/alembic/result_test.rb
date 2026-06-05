require "test_helper"

module Alembic
  class ResultTest < ActiveSupport::TestCase
    test "reports its slot" do
      assert Result.new(slot: :tier).tier?
    end
  end
end
