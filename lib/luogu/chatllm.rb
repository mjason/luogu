module Luogu
  class ChatLLM < Base

    setting :provider do
      setting :parameter_model, default: ->() {
        OpenAI::ChatRequestParams.new(
          model: 'gpt-3.5-turbo',
          temperature: Application.config.openai.temperature
        )
      }
      setting :request, default: ->(params) { OpenAI.chat(params: params) }
      setting :parse, default: ->(response) { OpenAI.get_content(response) }
      setting :find_final_answer, default: ->(content) { OpenAI.find_final_answer(content) }
      setting :history_limit, default: Application.config.openai.history_limit
    end

    attr_accessor :context
    attr_reader :plugin

    def initialize(file, history_path='.', plugin_file_path=nil)
      @plugin_file_path = plugin_file_path || file.sub(File.extname(file), ".plugin.rb")
      if File.exist?(@plugin_file_path)
        @plugin = Plugin.new(@plugin_file_path).load()
      else
        @plugin = Plugin.new(@plugin_file_path)
      end
      @history_path = history_path
      @prompt_file = file
      @prompt = PromptParser.new(file)
      @row_history = []
      @histories = HistoryQueue.new provider.history_limit

      @request_params = provider.parameter_model.call

      @context = OpenStruct.new

      run_plugin :setup
    end

    def run_plugin(method_name, &block)
      plugin.run method_name: method_name, llm: self, context: @context, &block
    end

    def provider
      config.provider
    end

    def request(messages)
      @request_params.messages = messages
      @context.request_params = @request_params
      run_plugin :before_request
      response = provider.request.call(@request_params.to_h)
      unless response.code == 200
        logger.error response.body.to_s
        raise RequestError
      end
      @context.response = response
      run_plugin :after_request

      provider.parse.call(response)
    end

    def chat(user_message)
      @context.user_input = user_message
      run_plugin :before_input do |context|
        user_message = context.user_input
      end

      messages = (@prompt.render + @histories.to_a) << { role: "user", content: user_message}
      run_plugin :after_input do
        messages = @context.request_messages
      end
      assistant_message = request(messages)
      
      self.push_row_history(user_message, assistant_message)

      if @prompt.ruby_code
        puts "执行文档中的callback"
        instance_eval @prompt.ruby_code, @prompt.file_path, @prompt.ruby_code_line
      elsif @plugin.before_save_history_proc
        @context.user_input = user_message
        @context.response_message = assistant_message

        run_plugin :before_save_history
      else
        puts "执行默认的历史记录"
        self.push_history(user_message, assistant_message)
      end

      run_plugin :after_save_history

      assistant_message
    end

    def push_row_history(user_message, assistant_message)
      @row_history << {role: "user", content: user_message}
      @row_history << {role: "assistant", content: assistant_message}
    end

    def push_history(user_message, assistant_message)
      @histories.enqueue({ role: "user", content: user_message})
      @histories.enqueue({ role: "assistant", content: assistant_message})
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
          self.class.save @histories.to_a, File.join(@history_path, "#{file_name}.history.md")
        when "row history"
          p @row_history
        when "history"
          p @histories.to_a
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
      self.class.save @histories.to_a, File.join(@history_path, "#{file_name}-#{now}.history.md")
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