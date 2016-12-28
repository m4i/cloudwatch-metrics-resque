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
                get_previous_processed(namespace),
              ).tap do |metric|
                set_previous_processed(namespace, metric.processed)
              end
            end
          end

          private

          def current_queue_sizes
            Resque.queues.map { |name| [name, Resque.size(name)] }
          end

          def get_previous_processed(namespace)
            @_previous_processed ||= {}
            @_previous_processed[namespace]
          end

          def set_previous_processed(namespace, previous_processed)
            @_previous_processed ||= {}
            @_previous_processed[namespace] = previous_processed
          end
        end

        def initialize(time, namespace, info, queue_sizes, previous_processed)
          @time = time
          @namespace = namespace
          @info = info
          @queue_sizes = queue_sizes
          @previous_processed = previous_processed
        end

        def pending;   @info[:pending];   end
        def processed; @info[:processed]; end
        def failed;    @info[:failed];    end
        def queues;    @info[:queues];    end
        def workers;   @info[:workers];   end
        def working;   @info[:working];   end

        def not_working
          [0, workers - working].max
        end

        def processing
          incremental_size_of_processed + working
        end

        def to_cloudwatch_metric_data
          %i(pending processed failed queues workers working not_working processing).map do |key|
            build_cloudwatch_metric_datum(camelize(key.to_s), public_send(key))
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

        def incremental_size_of_processed
          if @previous_processed.nil?
            0
          else
            [0, processed - @previous_processed].max
          end
        end

        def camelize(string)
          string.gsub(/(?:^|_)(.)/) { $1.upcase }
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
