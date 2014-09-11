module Elasticsearch
  module Persistence
      module Querying
        delegate :first, :first!, :last, :last!, :exists?, :any?, :many?, to: :all
        delegate :order, :limit, :where, :rewhere, :eager_load, :includes,  :create_with, :none, :unscope, to: :all

        def fetch(es)
          gateway.search(es.to_elastic, es.search_options)
        end

      end
    end
end
