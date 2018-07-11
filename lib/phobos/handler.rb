module Phobos
  module Handler
    def self.included(base)
      base.extend(ClassMethods)
    end

    def before_consume(payload, metadata)
      payload
    end

    def consume(payload, metadata)
      raise NotImplementedError
    end

    module ClassMethods
      def start(kafka_client)
      end

      def stop
      end

      def around_consume(payload, metadata)
        yield
      end
    end
  end
end
