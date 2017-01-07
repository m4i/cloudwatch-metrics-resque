# frozen_string_literal: true

module CloudWatchMetrics
  class Resque
    class Builder
      def initialize(metrics)
        @metric_names = metrics.select do |key, value|
          value && key != :pending_per_queue
        end.keys
      end

      def build(info)
        @info = info

        metric_data = @metric_names.map do |key|
          build_datum(camelize(key.to_s), @info.public_send(key))
        end

        metric_data.concat(build_per_queue) if @info.queue_sizes

        metric_data
      end

      private

      def build_per_queue
        @info.queue_sizes.map do |name, size|
          build_datum('Pending', size, Queue: name)
        end
      end

      def build_datum(metric_name, value, dimensions = {})
        {
          metric_name: metric_name,
          dimensions:  default_dimensions.merge(dimensions).to_cloudwatch,
          timestamp:   @info.time,
          value:       value,
          unit:        'Count',
        }
      end

      def default_dimensions
        Dimensions.new(Namespace: @info.namespace.to_s)
      end

      def camelize(string)
        string.gsub(/(?:^|_)(.)/) { Regexp.last_match(1).upcase }
      end
    end
  end
end
