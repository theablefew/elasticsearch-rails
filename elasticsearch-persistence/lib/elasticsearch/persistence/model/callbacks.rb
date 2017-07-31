module Elasticsearch
  module Persistence
    module Model
      module Callbacks

        extend ActiveSupport::Concern


        class_methods do
          @@_circuit_breaker_callbacks = []

          def circuit_breaker_callbacks
            @@_circuit_breaker_callbacks
          end

          def query_must_have(*args, &block)
            options = args.extract_options!

            cb = block_given? ? block : options[:validate_with]

            options[:message] = "does not exist in #{options[:in]}." unless options.has_key? :message

            @@_circuit_breaker_callbacks << {name: args.first, options: options, callback: cb}

          end
        end

      end
    end
  end
end
