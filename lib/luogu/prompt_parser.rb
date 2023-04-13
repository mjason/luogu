module Luogu
  class PromptParser
    attr_reader :ruby_code, :ruby_code_line, :file_path, :messages
    def initialize(file_path)
      @file_path = file_path
      @messages = []
      @ruby_code = nil
      @ruby_code_line = nil
    end

    def render
      process_file
      @messages
    end

    def to_json
      JSON.pretty_generate self.render
    end

    def process_file
      @messages = []
      file = File.read(@file_path)

      if file =~ /@callback/
        callback_regex = /@callback\n```ruby\n(.*?)\n```/m
        @ruby_code = file[callback_regex, 1]
        @ruby_code_line = self.find_line_number(file, "@callback") + 2
        file = file.gsub(callback_regex, '')
      end

      file.split(/(?=@u|@a|@s)/).reject(&:empty?).each do |c|
        role = if c =~ /^@s/
          "system"
        elsif c =~ /^@u/
          "user"
        elsif c =~ /^@a/
          "assistant"
        end
        content = c.sub(/^@(u|a|s)\s+/, '').strip
        @messages << {role: role, content: content}
      end
    end

    def find_line_number(text, search_str)
      lines = text.split("\n")
      line_number = nil
    
      lines.each_with_index do |line, index|
        if line.include?(search_str)
          line_number = index + 1
          break
        end
      end
    
      line_number
    end

  end
end