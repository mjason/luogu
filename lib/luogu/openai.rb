module Luogu::OpenAI

  class ChatRequestBody < Struct.new(:model, :messages, :temperature, 
    :top_p, :n, :stream, :stop, :max_tokens, 
    :presence_penalty, :frequency_penalty, :logit_bias, :user)

    def initialize(*args)
      defaults = { model: "gpt-3.5-turbo", messages: []}
      super(*defaults.merge(args.first || {}).values_at(*self.class.members))
    end

    def to_h
      super.reject { |_, v| v.nil? }
    end

    alias to_hash to_h
  end

  class RequestError < StandardError
  end

  class Client
    def initialize
      @access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
      @client = HTTP.auth("Bearer #{@access_token}").persistent "https://api.openai.com"
    end

    def chat(parameters: nil, params: nil, retries: 3)
      params ||= parameters
      retries_left = ENV.fetch('OPENAI_REQUEST_RETRIES', retries)
      begin
        @client.post('/v1/chat/completions', json: params)
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
  end
end
