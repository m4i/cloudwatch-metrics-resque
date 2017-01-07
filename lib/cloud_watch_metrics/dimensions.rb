# frozen_string_literal: true

module CloudWatchMetrics
  class Dimensions < Hash
    def initialize(hash)
      super()
      replace(hash)
    end

    def to_cloudwatch
      map { |name, value| { name: name, value: value } }
    end
  end
end
