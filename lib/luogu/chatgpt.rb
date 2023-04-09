module Luogu
  class ChatGPT
    def initialize(file)
      @temperature = ENV.fetch('OPENAI_TEMPERATURE', '0.7').to_f
      @limit_history = ENV.fetch('OPENAI_LIMIT_HISTORY', '6').to_i * 2
      
      @prompt = PromptParser.new(file)
      @row_history = []
      @history = HistoryQueue.new @limit_history
    end

    def request(messages)
      response = client.chat(
        parameters: {
            model: "gpt-3.5-turbo",
            messages: messages,
            temperature: 0.7,
        })
      response.dig("choices", 0, "message", "content")
    end

    def chat(user_message)
      messages = (@prompt.render + @history.to_a) << {role: "user", content: user_message}
      assistant_message = self.request(messages)
      
      self.push_row_history(user_message, assistant_message)

      if @prompt.ruby_code
        puts "执行文档中的callback"
        instance_eval @prompt.ruby_code, @prompt.file_path, @prompt.ruby_code_line
      else
        puts "执行默认的历史记录"
        self.push_history(user_message, assistant_message)
      end

      assistant_message
    end

    def push_row_history(user_message, assistant_message)
      @row_history << {role: "user", content: user_message}
      @row_history << {role: "assistant", content: assistant_message}
    end

    def push_history(user_message, assistant_message)
      @history.enqueue({role: "user", content: user_message})
      @history.enqueue({role: "assistant", content: assistant_message})
    end

    def ask(message)
      TTY::Prompt.new.ask(message)
    end

    def puts(message)
      @_puts_method ||= if system("which glow > /dev/null 2>&1")
        require 'shellwords'   
        -> (message) {
          system("echo #{Shellwords.escape(message)} | glow -") 
        }
      else
        -> (message) { puts message }
      end
      @_puts_method.call message
    end

    def run
      loop do
        # 从命令行读取输入
        input = self.ask("请输入你的指令>").cover_chinese
      
        # 根据用户输入执行相应的操作
        case input
        when "save"
          self.class.save @row_history, "./prompt.row_history.md"
          self.class.save @history.to_a, "./prompt.history.md"
        when "row history"
          p @row_history
        when "history"
          p @history.to_a
        when "exit"
          puts "再见！"
          break
        else
          self.puts self.chat(input)
        end
      end
    end

    def playload(messages)
      messages.each do |message|
        puts "test: #{message}"
        self.puts self.chat(message)
      end
      now = Time.now.to_i
      self.class.save @row_history, "./prompt.row_history.test-#{now}.md"
      self.class.save @history.to_a, "./prompt.history.test-#{now}.md"
    end

    class << self
      def save(history, file_path)
        text = ""
        role_map = {"user" => "@u", "assistant" => "@a", "system" => "@s"}
        history.each do |item|
          text += role_map[item[:role]]
          text += "\n"
          text += item[:content]
          text += "\n\n"
        end
        File.open(file_path, 'w') do |f|
          f.write(text)
        end
        puts "已经保存文件到 #{file_path}"
      end
    end
  end
end