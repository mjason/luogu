require "http"
require 'dotenv/load'
require "tty-prompt"
require 'json'
require 'yaml'
require 'fileutils'
require 'ostruct'
require 'benchmark'
require 'erb'
require 'logger'
require 'securerandom'

require "dry/cli"
require 'dry-configurable'

require_relative 'base'
require_relative 'error'
require_relative 'application'

require_relative "prompt_template"
require_relative 'plugin'
require_relative 'history_queue'
require_relative "prompt_parser"
require_relative "chatllm"
require_relative "cli"

require_relative "agent"
require_relative "agent_runner"

require_relative 'openai'
require_relative 'terminal'

require_relative 'aiui'

class String
  def cover_chinese
    self.gsub(/[\uFF01-\uFF0F]/) {|s| (s.ord-65248).chr}
  end
end