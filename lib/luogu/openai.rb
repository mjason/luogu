module Luogu::OpenAI
  class Client
    def initialize
      @access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
      @client = HTTP.auth("Bearer #{@access_token}").persistent "https://api.openai.com"
    end

    def chat(parameters: _params, params: nil, retries: 3)
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