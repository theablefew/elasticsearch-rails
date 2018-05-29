module Elasticsearch
  module Persistence
    module Model

      # Subclass of `Hashie::Mash` to wrap Hash-like structures
      # (responses from Elasticsearch, search definitions, etc)
      #
      # The primary goal of the subclass is to disable the
      # warning being printed by Hashie for re-defined
      # methods, such as `sort`.
      #
      class HashWrapper < ::Hashie::Mash
        disable_warnings if respond_to?(:disable_warnings)
      end
    end
  end
end
