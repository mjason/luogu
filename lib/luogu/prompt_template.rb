module Luogu
  class PromptTemplate
    def initialize(file_path)
      @file_path = file_path
      @template = ERB.new(File.read(@file_path), trim_mode: '-')
    end

    def result(_binding_ = nil)
      @template.result(_binding_ || binding)
    end

    alias render result

    class << self
      def load(file_path)
        self.new(file_path)
      end

      def load_template(file_name)
        self.new File.join(File.dirname(__FILE__), 'templates', file_name)
      end
    end
  end
end