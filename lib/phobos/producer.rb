module Phobos
  module Producer
    def self.included(base)
      base.extend(Phobos::Producer::ClassMethods)
    end

    def producer
      Phobos::Producer::PublicAPI.new(self)
    end

    class PublicAPI
      def initialize(host_obj)
        @host_obj = host_obj
      end

      def publish(topic, payload, key = nil, headers = {})
        class_producer.publish(topic, payload, key, headers)
      end

      def async_publish(topic, payload, key = nil, headers = {})
        class_producer.async_publish(topic, payload, key, headers)
      end

      # @param messages [Array(Hash(:topic, :payload, :key))]
      #        e.g.: [
      #          { topic: 'A', payload: 'message-1', key: '1' },
      #          { topic: 'B', payload: 'message-2', key: '2' }
      #        ]
      #
      def publish_list(messages)
        class_producer.publish_list(messages)
      end

      def async_publish_list(messages)
        class_producer.async_publish_list(messages)
      end

      private

      def class_producer
        @host_obj.class.producer
      end
    end

    module ClassMethods
      def producer
        Phobos::Producer::ClassMethods::PublicAPI.new
      end

      class PublicAPI
        NAMESPACE = :phobos_producer_store
        ASYNC_PRODUCER_PARAMS = %i(max_queue_size delivery_threshold delivery_interval).freeze

        # This method configures the kafka client used with publish operations
        # performed by the host class
        #
        # @param kafka_client [Kafka::Client]
        #
        def configure_kafka_client(kafka_client)
          async_producer_shutdown
          producer_store[:kafka_client] = kafka_client
        end

        def kafka_client
          producer_store[:kafka_client]
        end

        def publish(topic, payload, key = nil, headers = {})
          publish_list([{ topic: topic, payload: payload, key: key, headers: headers }])
        end

        def publish_list(messages)
          client = kafka_client || configure_kafka_client(Phobos.create_kafka_client)
          producer = client.producer(regular_configs)
          produce_messages(producer, messages)
          producer.deliver_messages
        ensure
          producer&.shutdown
        end

        def create_async_producer
          client = kafka_client || configure_kafka_client(Phobos.create_kafka_client)
          async_producer = client.async_producer(async_configs)
          producer_store[:async_producer] = async_producer
        end

        def async_producer
          producer_store[:async_producer]
        end

        def async_publish(topic, payload, key = nil, headers = {})
          async_publish_list([{ topic: topic, payload: payload, key: key, headers: headers }])
        end

        def async_publish_list(messages)
          producer = async_producer || create_async_producer
          produce_messages(producer, messages)
          producer.deliver_messages unless async_automatic_delivery?
        end

        def async_producer_shutdown
          async_producer&.deliver_messages
          async_producer&.shutdown
          producer_store[:async_producer] = nil
        end

        def regular_configs
          Phobos.config.producer_hash.reject { |k, _| ASYNC_PRODUCER_PARAMS.include?(k)}
        end

        def async_configs
          Phobos.config.producer_hash
        end

        private

        def produce_messages(producer, messages)
          messages.each do |message|
            headers = message[:headers].transform_keys(&:to_s).transform_values(&:to_s)
            producer.produce(message[:payload], topic: message[:topic],
                                                key: message[:key],
                                                partition_key: message[:key],
                                                headers: headers
            )
          end
        end

        def async_automatic_delivery?
          async_configs.fetch(:delivery_threshold, 0) > 0 ||
            async_configs.fetch(:delivery_interval, 0) > 0
        end

        def producer_store
          Thread.current[NAMESPACE] ||= {}
        end
      end
    end
  end
end
