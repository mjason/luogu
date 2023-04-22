# Luogu

> 锣鼓，现在的写代码就如古代的求神仪式一样，以前敲锣打鼓求天，现在敲锣打鼓求大模型，PS.本文档也是通过GPT来做优化的，具体查看`prompt.md`和`prompt.plugin.rb`

Luogu是一个针对产品经理的Prompt设计工具，可以帮助你更方便地编写和测试Prompt。

## 安装

1. 安装Ruby，要求2.6以上，Mac自带不需要再安装
2. 在终端中运行`gem install luogu`命令安装Luogu
3. 如果使用Mac可能需要使用sudo权限
4. 如果需要在终端显示markdown，需要安装[glow](https://github.com/charmbracelet/glow)

## 使用

Luogu提供了以下命令：

```Bash
Commands:
  luogu build PROMPT_FILE [TARGET_FILE]                      # 编译 Prompt.md 成能够提交给 ChatGPT API 的 messages. 默认输出为 <同文件名>.json
  luogu generate JSON_FILE [PROMPT_FILE]                     # 根据 ChatGPT messages JSON 来生成 Prompt.md
  luogu run PROMPT_FILE                                      # 编译 Prompt.md 成能够提交给 ChatGPT API 的 messages. 默认输出为 <同文件名>.json
  luogu test [PROMPT_FILE] [TEST_FILE]                       # 测试 Prompt 文件
  luogu version                                              # 打印版本
```

你可以在项目目录的.env中设置下面的环境变量，或者直接系统设置：

```
OPENAI_ACCESS_TOKEN=zheshiyigetoken
OPENAI_TEMPERATURE=0.7
OPENAI_LIMIT_HISTORY=6
```

## 进入run模式

在run模式下，你可以使用以下命令：

- save：保存对话
- row history：查看对话历史
- history：查看当前上下文
- exit：退出

## 插件模式

在run和test中可以使用插件模式，可以使用--plugin=<file>.plugin.rb。默认情况下，你可以使用<文件名>.plugin.rb来实现一个prompt.md的插件。

在插件中有两个对象：

```ruby
#gpt
gpt.row_history # 访问裸的历史记录 可读写
gpt.history # 处理过的历史记录 可读写
gpt.temperature # 设置请求的 temperature
gpt.model_name # 获取模型名称

#context
OpenStruct.new(
  request_params: params, # 请求参数
  user_input: user_message, # 用户输入
  request_messages: messages, #请求时的messages
  response_message: assistant_message, # 回复的message
  response: response # 回复的response
)
# 如果需要在方法中使用使用变量传递，必须使用context包括你要的变量名，比如 context.name = "luogu"
```

支持的回调：

```ruby
# 所有方法都必须返回context
# 可以使用
# require 'irb'
# binding.irb
# 来调试断点

setup do |gpt, context|
  puts gpt
  context
end

before_input do |gpt, context|
  puts "用户输入了: #{context.user_input}"
  context
end

after_input do |gpt, context|
  context
end

before_request do |gpt, context|
  puts "request params: "
  puts context
  context
end

after_request do |gpt, context|
  context
end

before_save_history do |gpt, context|
  context
end

after_save_historydo |gpt, context|
  context
end
```

## 示例

下面是一个prompt.md的示例：

```
@s
你是一个罗纳尔多的球迷

@a
好的

@u
罗纳尔多是谁？

@a
是大罗，不是C罗
```

如果需要处理历史记录的是否进入上下文可以使用，在prompt.md写入：

@callback
```ruby
if assistant_message =~ /```ruby/
  puts "记录本次记录"
  self.push_history(user_message, assistant_message)
else
  puts "抛弃本次记录"
end
```

## 更新记录

- 0.1.15：http库替换成HTTP.rb并且加入了重试机制，默认为3次，可通过设置环境变量OPENAI_REQUEST_RETRIES来设置次数
- 0.1.16：增加对agent的支持
- 0.2.0：重构了代码，agent的支持基本达到可用状态，具体看`bin/agent.rb`示例，有破坏性更新，不兼容0.1.x的agent写法

## License

This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file for details.
