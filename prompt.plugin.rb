before_input do |gpt, context|
  context.user_input = File.read("./README.md")
  context
end

after_request do |gpt, context|
  puts context.response
  context
end