# frozen_string_literal: true

module Luogu::OpenAI
  class ChatRequestParams < Struct.new(:model, :messages, :temperature,
                                     :top_p, :n, :stream, :stop,
                                     :max_tokens, :presence_penalty,
                                     :frequency_penalty, :logit_bias, :user)
    def initialize(*args)
      super(*(args.first || {}).values_at(*self.class.members))
    end
    
    def to_h
      super.reject { |_, v| v.nil? }
    end

    alias to_hash to_h
  end

  def chat(parameters: nil, params: nil, retries: nil)
    params ||= parameters
    retries_left = retries || Luogu::Application.config.openai.retries
    begin
      client.post('/v1/chat/completions', json: params)
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
    @client ||= HTTP.auth("Bearer #{Luogu::Application.config.openai.access_token}")
                    .persistent Luogu::Application.config.openai.host
  end

  def parse_json(markdown)
    json_regex = /```json(.+?)```/im
    json_blocks = markdown.scan(json_regex)
    result_json = nil
    json_blocks.each do |json_block|
      json_string = json_block[0]
      result_json = JSON.parse(json_string)
    end

    if result_json.nil?
      JSON.parse markdown
    else
      result_json
    end
  end

  def chat_response_handle(response)
    parse_json get_content(response)
  end

  def get_content(response)
    response.parse.dig("choices", 0, "message", "content")
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

  module_function :chat, :client, :parse_json, :chat_response_handle, :find_final_answer, :get_content
end
