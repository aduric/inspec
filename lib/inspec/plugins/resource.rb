# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

module Inspec
  module ResourceBehaviors
    def to_s
      @__resource_name__
    end

    # Overwrite inspect to provide better output to RSpec results.
    #
    # @return [String] full name of the resource
    def inspect
      to_s
    end
  end

  module ResourceDSL
    def name(name = nil)
      return if name.nil?
      @name = name
      __register(name, self)
    end

    def desc(description = nil)
      return if description.nil?
      __resource_registry[@name].desc(description)
    end

    def example(example = nil)
      return if example.nil?
      __resource_registry[@name].example(example)
    end

    def __resource_registry
      Inspec::Resource.registry
    end

    def __register(name, obj)
      cl = Class.new(obj) do
        def initialize(backend, name, *args)
          @resource_skipped = nil
          @resource_failed = nil

          # attach the backend to this instance
          @__backend_runner__ = backend
          @__resource_name__ = name

          # call the resource initializer
          begin
            super(*args)
          rescue Inspec::Exceptions::ResourceSkipped => e
            skip_resource(e.message)
          rescue Inspec::Exceptions::ResourceFailed => e
            fail_resource(e.message)
          end
        end

        def self.desc(description = nil)
          return @description if description.nil?
          @description = description
        end

        def self.example(example = nil)
          return @example if example.nil?
          @example = example
        end

        def skip_resource(message)
          @resource_skipped = message
        end

        def resource_skipped?
          !@resource_skipped.nil?
        end

        def resource_skipped_message
          @resource_skipped
        end
        # This alias exists for backwards compatibility
        # It is more idiomatic to have a `?` and `_message` methods
        # TODO: Remove in InSpec 2.0
        alias_method :resource_skipped, :resource_skipped_message

        def fail_resource(message)
          @resource_failed = message
        end

        def resource_failed?
          !@resource_failed.nil?
        end

        def resource_failed_message
          @resource_failed
        end

        def inspec
          @__backend_runner__
        end
      end

      # rubocop:enable Lint/NestedMethodDefinition
      if __resource_registry.key?(name)
        Inspec::Log.warn("Overwriting resource #{name}. To reference a specific version of #{name} use the resource() method")
      end
      __resource_registry[name] = cl
    end
  end

  module Plugins
    class Resource
      extend Inspec::ResourceDSL
      include Inspec::ResourceBehaviors
    end
  end
end
