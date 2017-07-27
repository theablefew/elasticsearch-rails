module Elasticsearch
  module Model
    module Callbacks
      extend ActiveSupport::Concern

      module ClassMethods
        def query_must_have(name, options = {}, &block)

          in_values = options.delete(:in)

          puts in_values
          puts self.send("#{in_values}_values".to_sym)
          puts name




        end
      end

    end
  end
end
