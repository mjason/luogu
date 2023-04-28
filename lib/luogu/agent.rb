module Luogu
  class Agent

    def initialize(row_input=nil)
      @row_input = row_input
    end

    attr_reader :row_input

    def call(input)
      raise NotImplementedError, "call method must be implemented in subclass"
    end

    class << self
      def desc(content)
        @_desc_ = content.gsub(/\n/, "")
      end

      def input_desc(content)
        @_input_desc_ = content
      end

      def set_name(agent_name)
        @_name_ = agent_name
      end

      def agent_name
        (@_name_ || self.to_s).gsub(/[[:punct:]]/, '')
      end

      def description
        @_desc_
      end

      def input_description
        @_input_desc_
      end
    end

  end
end