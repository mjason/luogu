module Luogu
  class ChatGPT

    attr_accessor :limit_history, :prompt, :row_history, :history, :temperature, :model_name, :context

    def initialize(file, history_path='.', plugin_file_path=nil)
      @plugin_file_path = plugin_file_path || file.sub(File.extname(file), ".plugin.rb")

      if File.exist?(@plugin_file_path)
        @plugin = Plugin.new(@plugin_file_path).load()
      else
        @plugin = Plugin.new(@plugin_file_path)
      end

      @temperature = ENV.fetch('OPENAI_TEMPERATURE', '0.7').to_f
      @limit_history = ENV.fetch('OPENAI_LIMIT_HISTORY', '6').to_i * 2
      @model_name = "gpt-3.5-turbo"
      
      @history_path = history_path
      @prompt_file = file

      @prompt = PromptParser.new(file)
      @row_history = []
      @history = HistoryQueue.new @limit_history

      @context = OpenStruct.new

      if @plugin.setup_proc
        @plugin.setup_proc.call(self, @context) 
      end
    end

    def request(messages)
      params = {
        model: @model_name,
        messages: messages,
        temperature: @temperature,
      }
      
      if @plugin.before_request_proc
        @context.request_params = params
        params = @plugin.before_request_proc.call(self, @context).request_params
      end
      response = client.chat(parameters: params).parse
      @context.response = response
      @plugin.after_request_proc.call(self, @context) if @plugin.after_request_proc
      response.dig("choices", 0, "message", "content")
    end

    def chat(user_message)
      if @plugin.before_input_proc
        @context.user_input = user_message
        user_message = @plugin.before_input_proc.call(self, @context).user_input
      end
      messages = (@prompt.render + @history.to_a) << {role: "user", content: user_message}
      if @plugin.after_input_proc
        @context.request_messages = messages
        messages = @plugin.after_input_proc.call(self, @context).request_messages
      end

      assistant_message = self.request(messages)
      
      self.push_row_history(user_message, assistant_message)

      if @prompt.ruby_code
        puts "执行文档中的callback"
        instance_eval @prompt.ruby_code, @prompt.file_path, @prompt.ruby_code_line
      elsif @plugin.before_save_history_proc
        @context.user_input = user_message
        @context.response_message = assistant_message
        @plugin.before_save_history_proc.call(self, @context)
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
      if @plugin.after_save_history_proc
        @context.user_input = user_message
        @context.response_message = response_message
        @plugin.after_save_history_proc.call(self, @context) 
      end
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
          file_name = File.basename(@prompt_file, ".*")
          self.class.save @row_history, File.join(@history_path, "#{file_name}.row_history.md")
          self.class.save @history.to_a, File.join(@history_path, "#{file_name}.history.md")
        when "row history"
          p @row_history
        when "history"
          p @history.to_a
        when "exit"
          puts "再见！"
          break
        else
          time = Benchmark.measure do
            self.puts self.chat(input)
          end
          puts "input: #{input} 执行时间为 #{time.real} 秒"
        end
      end
    end

    def playload(messages)
      messages.each do |message|
        time = Benchmark.measure do
          puts "test: #{message}"
          self.puts self.chat(message)
        end
        puts "test: #{message} 执行时间为 #{time.real} 秒"
      end
      now = Time.now.to_i
      file_name = File.basename(@prompt_file, ".*")

      self.class.save @row_history, File.join(@history_path, "#{file_name}-#{now}.row_history.md")
      self.class.save @history.to_a, File.join(@history_path, "#{file_name}-#{now}.history.md")
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
        FileUtils.mkdir_p(File.dirname(file_path))
        File.open(file_path, 'w') do |f|
          f.write(text)
        end
        puts "已经保存文件到 #{file_path}"
      end
    end
  end
end