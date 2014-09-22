require 'active_support'

if defined?(Rails)
  if Rails::VERSION::MAJOR >= 4
    require 'active_support'
    require 'active_support/rails'
    require 'active_support/per_thread_registry'
  elsif Rails::VERSION::MAJOR == 3
    require 'active_support/dependencies/autoload'
    require 'active_support/concern'
    require 'active_support/core_ext/class/attribute'
    require 'active_support/core_ext/module/delegation'
    require 'active_support/deprecation'
    require 'active_support/inflector'
    require 'elasticsearch/per_thread_registry'
  end
end
