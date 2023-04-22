require "bundler/setup"
require "luogu"

class WeatherAgent < Luogu::Agent
  desc "查询天气。输入必须是一个JSON数据{\"location\": \"地点\", \"date\": \"时间\"}。"

  def call(input)
    data = JSON.parse(input)
    unless data["date"].is_a? Integer
      "你输入的时间有错误，时间需要用unix时间表达，当前时间为: #{Time.now.to_i}"
    else
      "广州市明天小雨转雷阵雨,23到26度,空气质量优"
    end
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

# puts runner.user_input_template
# runner.chat "查询广州明天的天气的同时用计算工具计算一下3加2除23加3"
# runner.chat "用计算工具计算一下3的阶乘"
# runner.chat "罗纳尔多是谁"
t = Luogu::Terminal.new
t.default do |input|
  runner.run(input)
end

t.action(:info) do |input|
  p runner
end

t.run

# puts runner.histories.to_a
# require "irb"
# binding.irb