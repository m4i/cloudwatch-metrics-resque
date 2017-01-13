# frozen_string_literal: true

require 'optparse'

require 'resque'

require 'cloud_watch_metrics'
require 'cloud_watch_metrics/resque/builder'
require 'cloud_watch_metrics/resque/info'
require 'cloud_watch_metrics/resque/version'

module CloudWatchMetrics
  class Resque
    include Base

    DEFAULT_NAMESPACE = 'Resque'
    DEFAULT_METRICS = {
      pending:           true,
      processed:         true,
      failed:            true,
      queues:            true,
      workers:           true,
      working:           true,
      pending_per_queue: true,
      not_working:       false,
      processing:        false,
    }.freeze

    class << self
      private

      def parse_arguments(args)
        {}.tap do |options|
          option_parser.parse(args, into: options)

          convert_symbol_keys_from_dash_to_underscore(options)

          redis = delete_keys(options, %i(host port socket password db))
          redis = options.delete(:url) if options.key?(:url)
          options[:redis] = redis unless redis.empty?

          options[:metrics] = delete_keys(options, DEFAULT_METRICS.keys)
        end
      end

      def option_parser
        OptionParser.new do |opt|
          opt.on('--namespace <namespace>', String)
          opt.on('--interval <seconds>', Float)
          opt.on('--dry-run', TrueClass)

          opt.on('-h', '--host <host>', String)
          opt.on('-p', '--port <port>', Integer)
          opt.on('-s', '--socket <socket>', String)
          opt.on('-a', '--password <password>', String)
          opt.on('-n', '--db <db>', String)
          opt.on('--url <url>', String)
          opt.on('--redis-namespace <namespace>', String)

          DEFAULT_METRICS.each_key do |key|
            opt.on("--[no-]#{key.to_s.tr('_', '-')}", TrueClass)
          end
        end
      end

      def convert_symbol_keys_from_dash_to_underscore(hash)
        hash.keys.each do |key|
          if key.match?('-')
            hash[key.to_s.tr('-', '_').to_sym] = hash.delete(key)
          end
        end
      end

      def delete_keys(hash, keys)
        hash
          .select { |key,| keys.include?(key) }
          .each_key { |key| hash.delete(key) }
      end
    end

    def initialize(
      namespace:       DEFAULT_NAMESPACE,
      interval:        nil,
      dry_run:         false,
      redis:           nil,
      redis_namespace: nil,
      metrics:         {}
    )
      @namespace = namespace
      @interval = interval
      @dry_run = dry_run
      ::Resque.redis = redis if redis
      @redis_namespace = redis_namespace
      @metrics = DEFAULT_METRICS.merge(metrics)
    end

    private

    def run_once
      metric_data = redis_namespaces.flat_map do |redis_namespace|
        builder.build(info(redis_namespace).update)
      end

      Util.put_metric_data(@namespace, metric_data, dry_run: @dry_run)
    end

    def redis_namespaces
      return [::Resque.redis.namespace] unless @redis_namespace
      return [@redis_namespace.to_sym] unless @redis_namespace.include?('*')

      suffix = ':queues'
      ::Resque.redis.redis.keys(@redis_namespace + suffix).map do |key|
        key[0...-suffix.length].to_sym
      end
    end

    def builder
      @_builder ||= Builder.new(@metrics)
    end

    def info(namespace)
      @_infos ||= {}
      @_infos[namespace] ||= Info.new(namespace, @metrics[:pending_per_queue])
    end
  end
end
