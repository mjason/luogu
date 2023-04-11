require "openai"
require 'dotenv/load'
require "tty-prompt"
require 'json'
require 'yaml'
require "dry/cli"
require 'fileutils'
require 'ostruct'

require_relative 'plugin'
require_relative 'history_queue'
require_relative "prompt_parser"
require_relative "chatgpt"
require_relative "cli"

def client
  $client ||= OpenAI::Client.new
end

class String
  def cover_chinese
    self.gsub(/[\uFF01-\uFF0F]/) {|s| (s.ord-65248).chr}
  end
end