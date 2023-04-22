# frozen_string_literal: true

module Luogu
  class Terminal < Base
    def initialize(desc: "请输入你的指令>")
      @desc = desc
      @default_action = nil
      @actions = []
    end

    def action(action_name, &block)
      @actions << { action_name: action_name, action_method: block }
    end

    def default(&block)
      @default_action = block
    end

    def run
      loop do
        # 从命令行读取输入
        input = ask(@desc).cover_chinese

        if input == 'exit'
          break
        end

        if (action = @actions.find { |h| h[:action_name].to_s == input })
          action.fetch(:action_method)&.call(input)
        else
          @default_action&.call(input)
        end
      end
    end

    def ask(message)
      TTY::Prompt.new.ask(message)
    end
  end
end
