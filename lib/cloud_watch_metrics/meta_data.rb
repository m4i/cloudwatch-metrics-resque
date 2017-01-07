# frozen_string_literal: true

require 'open-uri'

module CloudWatchMetrics
  module MetaData
    class << self
      def instance_id
        open('http://169.254.169.254/latest/meta-data/instance-id', &:read)
      end
    end
  end
end
