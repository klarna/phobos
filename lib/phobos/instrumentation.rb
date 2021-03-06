# frozen_string_literal: true

require 'active_support/notifications'

module Phobos
  module Instrumentation
    NAMESPACE = 'phobos'

    def self.subscribe(event)
      ActiveSupport::Notifications.subscribe("#{NAMESPACE}.#{event}") do |*args|
        yield ActiveSupport::Notifications::Event.new(*args) if block_given?
      end
    end

    def self.unsubscribe(subscriber)
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    def instrument(event, extra = {})
      ActiveSupport::Notifications.instrument("#{NAMESPACE}.#{event}", extra) do |args|
        yield(args) if block_given?
      end
    end
  end
end
