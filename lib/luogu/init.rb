require "http"
require 'dotenv/load'
require "tty-prompt"
require 'json'
require 'yaml'
require "dry/cli"
require 'fileutils'
require 'ostruct'
require 'benchmark'
require 'erb'
require 'logger'

require_relative "prompt_template"
require_relative 'openai'
require_relative 'plugin'
require_relative 'history_queue'
require_relative "prompt_parser"
require_relative "chatgpt"
require_relative "cli"

require_relative "agent"
require_relative "session"
require_relative "agent_runner"



def client
  $client ||= Luogu::OpenAI::Client.new
end

def logger_init
  logger = Logger.new(STDOUT)
  logger.level = ENV['LOG_LEVEL'] ? Logger.const_get(ENV['LOG_LEVEL']) : Logger::INFO
  logger
end

def logger
  $logger ||= logger_init
end

class String
  def cover_chinese
    self.gsub(/[\uFF01-\uFF0F]/) {|s| (s.ord-65248).chr}
  end
end