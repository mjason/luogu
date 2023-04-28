# frozen_string_literal: true

module Luogu
  module Xinghuo
    extend Dry::Configurable
    class Messages
      def initialize
        @messages = []
      end

      def user(text: nil, file: nil)
        data = text || File.read(file)
        @messages << {role: "user", content: data}
        self
      end

      def assistant(text: nil, file: nil)
        data = text || File.read(file)
        @messages << {role: "assistant", content: data}
        self
      end

      def to_a
        @messages
      end

      class << self
        def create
          self.new
        end
      end
    end

    class ChatRequestParams < Struct.new(:auditing, :messages, :domain,
                                         :max_tokens, :random_threshold)
      def to_h
        super.reject { |_, v| v.nil? }
      end

      alias to_hash to_h
    end

    setting :provider do
      setting :parameter_model, default: ->() {
        Luogu::Xinghuo::ChatRequestParams.new(
          auditing: 'default',
          domain: 'general',
          max_tokens: 1024,
          random_threshold: 0
        )
      }
      setting :request, default: ->(params) { Luogu::Xinghuo.chat(params: params) }
      setting :parse, default: ->(response) { Luogu::Xinghuo.chat_response_handle response }
      setting :find_final_answer, default: ->(content) { Luogu::Xinghuo.find_final_answer(content) }
      setting :history_limit, default: Application.config.xinghuo.history_limit
    end

    setting :templates do
      setting :system, default: nil
      setting :user, default: PromptTemplate.load_template('xinghuo_agent_input.md.erb')
      setting :tool, default: PromptTemplate.load_template('xinghuo_agent_tool_input.md.erb')
    end

    def find_final_answer(content)
      if content.is_a?(Hash) && content['action'] == 'Final Answer'
        content['action_input']
      elsif content.is_a?(Array)
        result = content.find { |element| element["action"] == "Final Answer" }
        if result
          result["action_input"]
        else
          nil
        end
      else
        nil
      end
    end

    def chat_response_handle(response)
      parse_text get_content(response)
    end

    def parse_text(text)
      # Luogu::Application.logger.info "parse_text: #{text}"
      final_answer = text.match(/最终答案：(.*)/)&.captures&.first&.strip
      action = text.match(/工具调用：(.*)/)&.captures&.first&.strip
      action_input = text.match(/工具输入：(.*)/)&.captures&.first&.strip

      if action && action_input
        { 'action' => action, 'action_input' => action_input }
      elsif final_answer
        { 'action' => 'Final Answer', 'action_input' => final_answer }
      else
        { 'action' => 'Final Answer', 'action_input' => text }
      end
    end

    def get_content(response)
      response.parse.dig('choices', 0, 'message', 'content')
    end

    def chat(parameters: nil, params: nil, retries: nil)
      params ||= parameters
      retries_left = retries || Luogu::Application.config.xinghuo.retries
      begin
        client.post('/external/ls_log/xf_completions', json: params)
      rescue HTTP::Error => e
        if retries_left > 0
          puts "retrying ..."
          retries_left -= 1
          sleep(1)
          retry
        else
          puts "Connection error #{e}"
          return nil
        end
      end
    end

    def client
      @client ||= HTTP.auth("Bearer #{Luogu::Application.config.xinghuo.access_token}")
                      .persistent Luogu::Application.config.xinghuo.host
    end

    module_function :chat, :client, :parse_text, :chat_response_handle, :find_final_answer, :get_content
  end
end
