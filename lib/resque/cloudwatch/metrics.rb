# frozen_string_literal: true

require 'resque/cloudwatch/metrics/version'
require 'optparse'
require 'aws-sdk-core'
require 'resque'

module Resque
  module CloudWatch
    class Metrics
      DEFAULT_CW_NAMESPACE = 'Resque'

      # http://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_limits.html
      MAX_METRIC_DATA_PER_PUT = 20

      class << self
        def run(args)
          new(parse_arguments(args)).run
        end

        def parse_arguments(args)
          options = {}
          redis = {}

          opt = OptionParser.new
          opt.on('-h', '--host <host>')           { |v| redis[:host] = v }
          opt.on('-p', '--port <port>')           { |v| redis[:port] = v }
          opt.on('-s', '--socket <socket>')       { |v| redis[:path] = v }
          opt.on('-a', '--password <password>')   { |v| redis[:password] = v }
          opt.on('-n', '--db <db>')               { |v| redis[:db] = v }
          opt.on('--url <url>')                   { |v| options[:redis] = v }
          opt.on('--redis-namespace <namespace>') { |v| options[:redis_namespace] = v }
          opt.on('--cw-namespace <namespace>')    { |v| options[:cw_namespace] = v }
          opt.on('-i', '--interval <interval>')   { |v| options[:interval] = v.to_f }
          opt.parse(args)

          options[:redis] ||= redis unless redis.empty?
          options
        end
      end

      def initialize(redis: nil,
                     redis_namespace: nil,
                     interval: nil,
                     cw_namespace: DEFAULT_CW_NAMESPACE)
        Resque.redis = redis if redis
        @redis_namespace = redis_namespace
        @interval = interval
        @cw_namespace = cw_namespace

        @mutex = Mutex.new
      end

      def run
        if @interval
          loop do
            thread = Thread.start { run_once }
            thread.abort_on_exception = true
            sleep @interval
          end
        else
          run_once
        end
      end

      private

      def run_once
        now, infos = @mutex.synchronize { [Time.now, get_infos] }
        put_metric_data(infos.flat_map { |args| build_metric_data(now, *args) })
      end

      def get_infos
        redis_namespaces.map do |redis_namespace|
          Resque.redis.namespace = redis_namespace
          [
            redis_namespace,
            Resque.info,
            Resque.queues.map { |name| [name, Resque.size(name)] },
          ]
        end
      end

      def redis_namespaces
        if @redis_namespace
          if @redis_namespace.include?('*')
            suffix = ':queues'
            Resque.redis.redis.keys(@redis_namespace + suffix).map do |key|
              key[0 ... - suffix.length].to_sym
            end
          else
            [@redis_namespace.to_sym]
          end
        else
          [Resque.redis.namespace]
        end
      end

      def build_metric_data(timestamp, redis_namespace, info, queue_sizes)
        dimensions = [{ name: 'namespace', value: redis_namespace.to_s }]

        %i(pending processed failed queues workers working).map do |key|
          {
            metric_name: key.to_s.capitalize,
            dimensions:  dimensions,
            timestamp:   timestamp,
            value:       info[key],
            unit:        'Count',
          }
        end +
        queue_sizes.map do |name, size|
          {
            metric_name: 'Pending',
            dimensions:  dimensions + [{ name: 'queue', value: name }],
            timestamp:   timestamp,
            value:       size,
            unit:        'Count',
          }
        end
      end

      def put_metric_data(metric_data)
        metric_data.each_slice(MAX_METRIC_DATA_PER_PUT).map do |data|
          Thread.start(data) do |data|
            cloudwatch.put_metric_data(
              namespace: @cw_namespace,
              metric_data: data,
            )
          end
        end.each(&:join)
      end

      def cloudwatch
        @_cloudwatch ||= Aws::CloudWatch::Client.new
      end
    end
  end
end
