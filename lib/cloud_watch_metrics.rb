# frozen_string_literal: true

module CloudWatchMetrics
  autoload :Base,       'cloud_watch_metrics/base'
  autoload :Dimensions, 'cloud_watch_metrics/dimensions'
  autoload :MetaData,   'cloud_watch_metrics/meta_data'
  autoload :Util,       'cloud_watch_metrics/util'
end
