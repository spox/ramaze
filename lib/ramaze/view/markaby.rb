require 'builder'
require 'markaby'

module Ramaze
    module View
        module Markaby
            # TODO: Use View.compile so we get caching support
            def self.call(action, string)
                return string if !string.is_a?(String) || string.empty?
                builder = ::Markaby::Builder.new(action.variables, action.instance)
                builder.instance_eval(string)
                return builder.to_s, 'text/html'
            end
        end
    end
end
