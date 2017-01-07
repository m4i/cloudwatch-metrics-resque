# frozen_string_literal: true

require 'resque'

module CloudWatchMetrics
  class Resque
    class Info
      attr_reader :namespace, :time, :queue_sizes

      def initialize(namespace, queue_sizes_enabled)
        @namespace = namespace
        @queue_sizes_enabled = queue_sizes_enabled
      end

      def update
        @previous_processed = processed if @info
        ::Resque.redis.namespace = @namespace
        @time = Time.now
        @info = ::Resque.info
        @queue_sizes = fetch_queue_sizes if @queue_sizes_enabled
        self
      end

      def pending
        @info.fetch(:pending)
      end

      def processed
        @info.fetch(:processed)
      end

      def failed
        @info.fetch(:failed)
      end

      def queues
        @info.fetch(:queues)
      end

      def workers
        @info.fetch(:workers)
      end

      def working
        @info.fetch(:working)
      end

      def not_working
        [0, workers - working].max
      end

      def processing
        incremental_size_of_processed + working
      end

      private

      def fetch_queue_sizes
        ::Resque.queues.map { |name| [name, ::Resque.size(name)] }
      end

      def incremental_size_of_processed
        if @previous_processed.nil?
          0
        else
          [0, processed - @previous_processed].max
        end
      end
    end
  end
end
