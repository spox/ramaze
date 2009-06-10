require 'builder'
require 'markaby'

class MarkablyTemplator < BlankSlate
    def self.process(string, args)
        template = ::Markaby::Template.new(string)
        return template.render(args)
    end
end

module Ramaze
    module View
        module Markaby
            def self.call(action, string)
                return if string.empty?
                return MarkablyTemplator.process(string, action.variables), 'text/html'
            end
        end
    end
end
