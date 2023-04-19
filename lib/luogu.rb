# frozen_string_literal: true

require_relative "luogu/version"
require_relative "luogu/init"

module Luogu
  class Error < StandardError; end
  # Your code goes here...

  module_eval do
    Dotenv.load
  end
end
