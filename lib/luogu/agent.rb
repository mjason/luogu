module Luogu
  class Agent

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

      def name
        self.to_s
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