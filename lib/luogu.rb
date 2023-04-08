# frozen_string_literal: true

require_relative "luogu/version"
require_relative "luogu/init"

module Luogu
  class Error < StandardError; end
  # Your code goes here...

  module_eval do
    Dotenv.load
    
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
    end
  end
end
