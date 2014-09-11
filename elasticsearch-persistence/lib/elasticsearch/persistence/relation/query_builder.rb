module Elasticsearch
  module Persistence
    class QueryBuilder

      attr_reader :structure, :values

      def initialize(values)
        @values = values
      end

      def facets
        values[:facet]
      end

      def filters
        values[:filter]
      end

      def query
        compact_where(values[:where])
      end

      def fields
        values[:fields]
      end

      def highlights
        values[:highlights]
      end

      def size
        values[:size]
      end

      def sort
        values[:order]
      end

      def query_filters
        values[:query_filter]
      end

      def search_options
        build_search_options
      end

      def to_elastic
        @structure = Jbuilder.new ignore_nil: true
        query_filters ? build_filtered_query : build_query
        build_sort unless sort.blank?
        build_highlights unless highlights.blank?
        build_filters unless filters.blank?
        build_facets unless facets.blank?
        structure.attributes!
      end

      private

      def build_query
        return if query.nil?
        structure.query do
          structure.query_string do
            structure.query query
          end
        end
      end

      def build_filtered_query
        structure.query do
          structure.filtered do
            build_query
            query_filters.each do |f|
              puts f
              structure.filter filter(f[:name], f[:args])
            end
          end
        end
      end

      def build_sort
        structure.sort sort
      end

      def build_highlights
        structure.highlights highlights
      end

      def build_filters
        filters.each do |f|
          structure.filter(f[:name], f[:args], &f[:l])
        end
      end

      def build_facets
        facets.each do |f|
          structure.facets tire.facet(f[:name], f[:args], &f[:l])
        end
      end

      def build_search_options
        values[:search_options] ||= []

        opts = extra_search_options
        (values[:search_options] + [opts]).compact.inject(Hash.new) { |h,k,v| h.merge(k) }
      end

      def extra_search_options
        [:size].inject(Hash.new) { |h,k| h[k] = self.send(k) unless self.send(k).nil?; h}
      end

      def compact_where(q)
        return if q.nil?

        _and = []
        q.each do |arg|
          arg.each_pair { |k,v|  _and << "#{k}:#{v}" } if arg.class == Hash
          _and << arg if arg.class == String
        end
        _and.join(" AND ")
      end

      def filter(name,opts = {})
        Jbuilder.new do |filter|
          filter.set! name do
            case
            when opts.is_a?(Hash)
                filter.extract! opts, *opts.keys
            when opts.is_a?(Array)
                extract_filter_arguments_from_array(filter, opts)
            else
              raise "Filter only accepts Hash or Array"
            end
            end
        end
      end

      def extract_filter_arguments_from_array(filter, opts)
        filter.child! do
          opts.each do |opt|
            filter.extract! opt, *opt.keys
          end
        end
      end

    end
  end
end
