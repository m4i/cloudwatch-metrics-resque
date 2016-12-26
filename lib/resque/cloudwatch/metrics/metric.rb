# frozen_string_literal: true

require 'resque'

module Resque
  module CloudWatch
    class Metrics
      class Metric
        class << self
          @@mutex = Mutex.new

          def create(namespace)
            @@mutex.synchronize do
              Resque.redis.namespace = namespace
              new(
                Time.now,
                namespace,
                Resque.info,
                current_queue_sizes,
              )
            end
          end

          private

          def current_queue_sizes
            Resque.queues.map { |name| [name, Resque.size(name)] }
          end
        end

        def initialize(time, namespace, info, queue_sizes)
          @time = time
          @namespace = namespace
          @info = info
          @queue_sizes = queue_sizes
        end

        def to_cloudwatch_metric_data
          dimensions = [{ name: 'namespace', value: @namespace.to_s }]

          %i(pending processed failed queues workers working).map do |key|
            build_cloudwatch_metric_datum(key.to_s.capitalize, @info[key])
          end +
          @queue_sizes.map do |name, size|
            build_cloudwatch_metric_datum('Pending', size, queue: name)
          end
        end

        private

        def build_cloudwatch_metric_datum(metric_name, value, dimensions = {})
          {
            metric_name: metric_name,
            dimensions:  default_dimensions.merge(dimensions).to_cloudwatch,
            timestamp:   @time,
            value:       value,
            unit:        'Count',
          }
        end

        def default_dimensions
          @_default_dimensions = Dimensions.new(namespace: @namespace.to_s)
        end
      end

      class Dimensions < Hash
        def initialize(hash)
          super()
          update(hash)
        end

        def to_cloudwatch
          map { |name, value| { name: name, value: value } }
        end
      end
    end
  end
end
