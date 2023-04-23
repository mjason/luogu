require "bundler/setup"
require "luogu"

class WeatherAgent < Luogu::Agent
  desc "查询天气。输入必须使用简洁有逻辑的中文语句，需要有时间和地点"

  def call(input)
    Luogu::AIUI.request(text: input)
  end
end

class CalculatorAgent < Luogu::Agent
  desc "数学运算. 输入必须是一个JSON{\"code\": \"可执行的ruby表达式\"}"

  def call(input)
    sum = eval JSON.parse(input)['code']
    "JSON.parse(input)['code'] 的结果是: #{sum}"
  end
end

runner = Luogu::AgentRunner.new
runner
  .register(WeatherAgent)
  .register(CalculatorAgent)

runner.run("明天广州的天气怎么样")
runner.run("后天呢")
runner.run("那么我应该穿什么样的衣服")