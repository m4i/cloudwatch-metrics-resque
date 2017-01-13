# frozen_string_literal: true

require 'json'

require 'aws-sdk-core'

module CloudWatchMetrics
  module Util
    # http://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_limits.html
    MAX_METRIC_DATA_PER_PUT = 20

    class << self
      def convert_symbol_keys_from_dash_to_underscore!(hash)
        hash.keys.each do |key|
          if key.match?('-')
            hash[key.to_s.tr('-', '_').to_sym] = hash.delete(key)
          end
        end
      end

      def delete_keys!(hash, keys)
        hash
          .select { |key,| keys.include?(key) }
          .each_key { |key| hash.delete(key) }
      end

      def accept_hash(option_parser)
        option_parser.accept(Hash) do |s,|
          break s unless s
          s
            .split(',').reject(&:empty?)
            .map { |kv| kv.include?('=') ? kv.split('=', 2) : [kv, true] }
            .to_h
        end
      end

      # @return [void]
      def put_metric_data(namespace, metric_data, dry_run: false)
        return dump_metric_data(namespace, metric_data) if dry_run

        metric_data.each_slice(MAX_METRIC_DATA_PER_PUT).map do |data|
          Thread.start(data, cloudwatch) do |data_, cloudwatch_|
            cloudwatch_.put_metric_data(
              namespace: namespace,
              metric_data: data_,
            )
          end
        end.each(&:join)
      end

      private

      def cloudwatch
        @_cloudwatch ||= Aws::CloudWatch::Client.new
      end

      def dump_metric_data(namespace, metric_data)
        json = { namespace: namespace, metric_data: metric_data }.to_json(
          indent:    ' ' * 2,
          space:     ' ',
          object_nl: "\n",
          array_nl:  "\n",
        )
        puts json
      end
    end
  end
end
