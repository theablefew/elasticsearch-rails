module Elasticsearch
  module Persistence

      module FinderMethods

        def first
          spawn.first!.to_a.first
        end

        def first!
          spawn.sort(Hash[default_sort_key, :asc]).spawn.size(1)
          self
        end

        def last
          spawn.last!.to_a.first
        end

        def last!
          spawn.sort(Hash[default_sort_key, :desc]).spawn.size(1)
          self
        end

        def count
          spawn.count!
        end

        def count!
          spawn.size(0).to_a.total
        end

      end
    end
end
