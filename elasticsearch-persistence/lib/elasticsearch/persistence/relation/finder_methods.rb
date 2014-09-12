module Elasticsearch
  module Persistence

      module FinderMethods

        def first
          spawn.first!.to_a.first
        end

        def first!
          spawn.sort(created_at: :asc).spawn.size(1)
          self
        end

        def last
          spawn.last!.to_a.first
        end

        def last!
          spawn.sort(created_at: :desc).spawn.size(1)
          self
        end

        def count
          spawn.count!
        end

        def count!
          spawn.search_type(:count).to_a.total
        end

      end
    end
end
