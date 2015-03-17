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

      def aggregations
        values[:aggregation]
      end

      def filters
        values[:filter]
      end

      def query
        @query ||= compact_where(values[:where])
      end

      def query_strings
        @query_string ||= compact_where(values[:query_string], bool: false)
      end

      def must_nots
        @must_nots ||= compact_where(values[:must_not])
      end

      def shoulds
        @shoulds ||= compact_where(values[:should])
      end

      def fields
        values[:field]
      end

      def source
        values[:source]
      end

      def highlights
        values[:highlight]
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
        build_fields unless fields.blank?
        build_source unless source.blank?
        build_aggregations unless aggregations.blank?
        build_facets unless facets.blank?
        structure.attributes!
      end

      private

      def missing_bool_query?
        query.nil? && must_nots.nil? && shoulds.nil?
      end

      def missing_query_string?
        query_strings.nil?
      end

      def build_query
        return if missing_bool_query? && missing_query_string?
        structure.query do
          structure.bool do
            structure.must query
            structure.must_not must_nots unless must_nots.nil?
            structure.should shoulds unless shoulds.nil?
          end unless missing_bool_query?

          structure.query_string do
            structure.query query_strings
          end unless query_strings.nil?
        end
      end

      def build_filtered_query
        structure.query do
          structure.filtered do
            build_query
            structure.filter do
              structure.and do
                query_filters.each do |f|
                  structure.child! do
                    structure.set! f[:name], extract_filters(f[:name], f[:args])
                  end
                end
              end
            end
          end
        end
      end

      def build_source
        structure._source do
          structure.include source.first.delete(:include) if source.first.has_key? :include
          structure.exclude source.first.delete(:exclude) if source.first.has_key? :exclude
        end
      end

      def build_sort
        structure.sort sort.flatten.inject(Hash.new) { |h,v| h.merge(v) }
      end

      def build_highlights
        structure.highlight do
          structure.fields do
            highlights.each do |highlight|
              structure.set! highlight, extract_highlighter(highlight)
            end
          end
        end
      end

      def build_filters
        filters.each do |f|
          structure.filter extract_filters(f[:name], f[:args])
        end
      end

      def build_aggregations
        structure.aggregations do
          aggregations.each do |agg|
            structure.set! agg[:name], facet(agg[:name], agg[:args])
          end
        end
      end

      def build_facets
        structure.facets do
          facets.each do |facet|
            structure.set! facet[:name], facet(facet[:name], facet[:args])
          end
        end
      end

      def build_fields
        structure.fields do
          structure.array! fields.flatten
        end
      end

      def build_search_options
        values[:search_option] ||= []

        opts = extra_search_options
        (values[:search_option] + [opts]).compact.inject(Hash.new) { |h,k,v| h.merge(k) }
      end

      def extra_search_options
        [:size].inject(Hash.new) { |h,k| h[k] = self.send(k) unless self.send(k).nil?; h}
      end

      def compact_where(q, opts = {bool:true})
        return if q.nil?
        if opts.delete(:bool)
          as_must(q)
        else
          as_query_string(q)
        end
      end

      def as_must(q)
        _must = []
        q.each do |arg|
          arg.each_pair { |k,v| _must << {term: Hash[k,v]} } if arg.class == Hash
        end
        _must.length == 1 ? _must.first : _must
      end

      def as_query_string(q)
        _and = []
        q.each do |arg|
          arg.each_pair { |k,v|  _and << "#{k}:#{v}" } if arg.class == Hash
          _and << arg if arg.class == String
        end
        _and.join(" AND ")
      end



      def extract_highlighter(highlighter)
        Jbuilder.new do |highlight|
          highlight.extract! highlighter
        end
      end

      def extract_filters(name,opts = {})
        Jbuilder.new do |filter|
            case
            when opts.is_a?(Hash)
                filter.extract! opts, *opts.keys
            when opts.is_a?(Array)
                extract_filter_arguments_from_array(filter, opts)
            else
              raise "#filter only accepts Hash or Array"
            end
        end
      end

      def facet(name, opts = {})
        Jbuilder.new do |facet|
          case
          when opts.is_a?(Hash)
              facet.extract! opts, *opts.keys
          when opts.is_a?(Array)
              extract_filter_arguments_from_array(facet, opts)
          else
            raise "#facet only accepts Hash or Array"
          end
        end
      end

      def extract_filter_arguments_from_array(element, opts)
        element.child! do
          opts.each do |opt|
            element.extract! opt, *opt.keys
          end
        end
      end

    end
  end
end
