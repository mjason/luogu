require "bundler/setup"
require "luogu"
require 'irb'
include Luogu

class WeatherAgent < Agent
  name "天气查询"
  desc "输入必须使用简洁有逻辑的文本"

  def call(input)
    text = Luogu::AIUI.request(text: input)&.dig("text")
    text
  end
end

class CalculatorAgent < Agent
  name "家居控制"
  desc "能够使用自然语言来控制智能家居，直接使用自然语言下指令即可"

  def call(input)
    "好的，已经帮你设置好了"
  end
end

AgentRunner.configure do |config|
  config.provider = Xinghuo.config.provider
  config.templates = Xinghuo.config.templates
end

runner = AgentRunner.new
runner
  .register(WeatherAgent)
  .register(CalculatorAgent)

# runner.run("一加一等于多少")
runner.run("我老婆今晚生日，你帮我设置一下家里的客厅环境")
runner.run("罗纳尔多是谁")
# runner.run("翻译一个错误成英文：输入必须是JSON并且包含action和action_input")
# runner.run("那么我应该穿什么样的衣服")