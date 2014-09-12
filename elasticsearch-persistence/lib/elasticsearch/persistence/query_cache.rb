module Elasticsearch
  module Persistence
    module QueryCache

      module CacheMethods
        mattr_accessor :force_cache
        @@force_cache = false

        def cache
          Elasticsearch::Persistence.force_cache = true
          lm = yield
          Elasticsearch::Persistence.force_cache = false
          lm
        end

        def setup_store!
          case ::Rails.application.config.goodyear_cache_store
           when :redis_store
             ActiveSupport::Cache::RedisStore
           when :memory_store
             ActiveSupport::Cache::MemoryStore
           else
             ActiveSupport::Cache::MemoryStore
           end.new(namespace: 'elasticsearch', expires_in: ::Rails.application.config.goodyear_expire_cache_in)
        end
      end

      def store
        @query_cache ||= Elasticsearch::Persistence.setup_store!
      end

      def cache_query(query, klass)
        cache_key = sha(query)
        Elasticsearch::Persistence.force_cache
        result = if store.exist?(cache_key) && Elasticsearch::Persistence.force_cache
            ActiveSupport::Notifications.instrument "cache.query.elasticsearch",
              name: klass.name,
              query: query

            store.fetch cache_key
          else
            res = []
            ActiveSupport::Notifications.instrument "query.elasticsearch",
              name: klass.name,
              query: query do
                res = yield
            end

            store.write(cache_key, res) if Elasticsearch::Persistence.force_cache
            res
          end
        result.dup
      end


      private

      def sha(str)
        Digest::SHA256.new.hexdigest(str)
      end

    end
  end
end
