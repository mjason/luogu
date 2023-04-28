require "bundler/setup"
require "luogu"
require 'irb'
include Luogu

class WeatherAgent < Agent
  name "天气查询"
  desc "仅能查询天气信息，工具输入要求是能够表达意图的文本"

  def call(input)
    text = Luogu::AIUI.request(text: input)&.dig("text")
    text
  end
end

class CalculatorAgent < Agent
  name "家居控制"
  desc "仅能做家居控制，工具输入要求是能够表达意图的文本"

  def call(input)
    "好的，已经帮你设置好了"
  end
end

class FinalAnswerAgent < Agent
  name "智能问答"
  desc "根据用户问题提供准确的回答"

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
  # .register(WeatherAgent)
  .register(CalculatorAgent)
  .register(FinalAnswerAgent)

# runner.run("一加一等于多少")
# runner.run("我老婆今晚生日，你帮我设置一下家里的客厅环境")
# runner.run("罗纳尔多是谁")
# runner.run("翻译一个错误成英文：输入必须是JSON并且包含action和action_input")
# runner.run("那么我应该穿什么样的衣服")

YAML.load_file("./prompt.test.yml").each do |prompt|
  Luogu.println "prompt: #{prompt}"
  runner.run(prompt)
  Luogu.println "----------------------------------------"
end