require "bundler/setup"
require "luogu"
require 'irb'
include Luogu

class WeatherAgent < Agent
  set_name "天气查询"
  desc "仅能查询天气信息，工具输入要求是能够表达意图的文本"

  def call(input)
    text = Luogu::AIUI.request(text: input)&.dig("text")
    text
  end
end

class SmartAgent < Agent
  set_name "智能家居控制助理"
  desc "使用自然语言控制家里的电器(例如：打开空调)，工具输入要求是能够表达意图的文本"

  def call(input)
    "搞定，已经按照你的要求完了所有控制"
  end
end


AgentRunner.configure do |config|
  config.provider = Xinghuo.config.provider
  config.templates = Xinghuo.config.templates
end

runner = AgentRunner.new
runner
  .register(SmartAgent)
  .register(WeatherAgent)
  # .register(FinalAnswerAgent)

Luogu::Xinghuo.configure do |config|
  config.agents = runner.agents
  config.handle_action_nil = ->(text) {
    { 'action' => 'Final Answer', 'action_input' => "不好意思，我不理解你的意思" }
  }
end

runner.run("一加一等于多少")
# runner.run("我老婆今晚生日，你帮我设置一下家里的客厅环境")
# runner.run("罗纳尔多是谁")
# runner.run("翻译一个错误成英文：输入必须是JSON并且包含action和action_input")
# runner.run("那么我应该穿什么样的衣服")

YAML.load_file("./prompt.test.yml").each do |prompt|
  Luogu.println "prompt: #{prompt}"
  runner.run(prompt)
  # Luogu.println "histories #{runner.histories.to_a}"
  Luogu.println "----------------------------------------"
end