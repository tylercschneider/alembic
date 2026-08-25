module Steps
  class Notify
    include Alembic::Flow::Step

    step_name "Notify"

    setting :message, type: :string
    setting :channels, type: :multi_select, options: %w[email sms push], limit: 2,
      check: ->(chosen) { "Channels needs at least one" if chosen.blank? }
  end
end
