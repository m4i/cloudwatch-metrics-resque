# frozen_string_literal: true

module CloudWatchMetrics
  module Base
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def run(args)
        new(parse_arguments(args)).run
      end
    end

    def run
      if @interval
        loop do
          start = Time.now
          Timeout.timeout(@interval * 2 - 1) { run_once }
          sleep((start - Time.now) % @interval)
        end
      else
        run_once
      end
    end
  end
end
