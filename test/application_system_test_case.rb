require "test_helper"
require "capybara/rails"
require "selenium-webdriver"

module Alembic
  class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
      options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
    end

    def canvas_for(diagnostic)
      visit alembic.manage_diagnostic_path(diagnostic)
      assert_selector "[data-flow-canvas]"
    end

    def step_card(id)
      find("[data-step='#{id}']")
    end

    def step_ids
      all("[data-step]").map { |card| card["data-step"] }
    end

    def alembic
      Alembic::Engine.routes.url_helpers
    end
  end
end
