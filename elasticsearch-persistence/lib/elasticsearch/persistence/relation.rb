module Elasticsearch
  module Persistence
    class Relation

        MULTI_VALUE_METHODS  = [:order, :where, :or_filter, :filter, :bind, :extending, :unscope, :skip_callbacks]
        SINGLE_VALUE_METHODS = [:limit, :offset, :routing, :size]

        INVALID_METHODS_FOR_DELETE_ALL = [:limit, :offset]

        VALUE_METHODS = MULTI_VALUE_METHODS + SINGLE_VALUE_METHODS

        include FinderMethods, SpawnMethods, QueryMethods, SearchOptionMethods, Delegation

        attr_reader :klass, :loaded
        alias :model :klass
        alias :loaded? :loaded

        delegate :blank?, :empty?, :any?, :many?, to: :results

        def initialize(klass, values={})
            @klass  = klass
            @values = values
            @offsets = {}
            @loaded = false
        end

        def build(*args)
         @klass.new *args
        end

        def to_a
          load
          @records
        end
        alias :results :to_a

        def as_json(options = nil)
          to_a.as_json(options)
        end

        def to_elastic
          query_builder.to_elastic
        end

        def create(*args, &block)
           scoping { @klass.create!(*args, &block) }
        end

        def scoping
          previous, klass.current_scope = klass.current_scope, self
          yield
        ensure
          klass.current_scope = previous
        end

        def load
          exec_queries unless loaded?

          self
        end
        alias :fetch :load

        def delete(opts=nil)
        end

        def exec_queries
          # Run safety callback
          klass.circuit_breaker_callbacks.each do |cb|
            current_scope_values = self.send("#{cb[:options][:in]}_values")
            next if skip_callbacks_values.include? cb[:name]
            valid = if cb[:callback].nil?
              current_scope_values.collect(&:keys).flatten.include? cb[:name]
            else
              cb[:callback].call(current_scope_values.collect(&:keys).flatten, current_scope_values)
            end

            raise Elasticsearch::Persistence::Model::QueryOptionMissing, "#{cb[:name]} #{cb[:options][:message]}" unless valid
          end

          @records = @klass.fetch_results(query_builder)

          @loaded = true
          @records
        end

        def values
          Hash[@values]
        end

        def inspect
          entries = to_a.results.take([size_value.to_i + 1, 11].compact.min).map!(&:inspect)
          message = {}
          message = {total: to_a.total, max: to_a.total}
          message.merge!(aggregations: results.aggregations.keys) unless results.aggregations.nil?
          message = message.each_pair.collect { |k,v|  "#{k}: #{v}" }
          message.unshift entries.join(', ') unless entries.size.zero?
          "#<#{self.class.name} #{message.join(', ')}>"
        end



        private

        def query_builder
          QueryBuilder.new(values)
        end

    end
  end
end
