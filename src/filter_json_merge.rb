require 'json'

module Fluent
  class JsonMergeFilter < Filter
    Fluent::Plugin.register_filter('json_merge', self)

    config_param :key, :string
    config_param :remove, :bool

    def configure(conf)
      super
    end

    def start
      super
    end

    def shutdown
      super
    end

    def filter(tag, time, record)
      if record.has_key? @key
        record = record.merge(record[@key])
        record.delete(@key) if @remove
      end
      return record
    end
  end
end
