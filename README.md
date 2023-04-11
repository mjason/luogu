# Luogu
> 锣鼓，现在的写代码就如古代的求神仪式一样，以前敲锣打鼓求天，现在敲锣打鼓求大模型

用来开发 prompt 工程的工具

### 安装
- 安装ruby，要求2.6以上，Mac自带不需要再安装
- gem install luogu
- 如果使用 mac 可能你需要使用sudu权限
- 如果需要在终端显示markdown，需要 [glow](https://github.com/charmbracelet/glow)

### 使用
```Bash
Commands:
  luogu build PROMPT_FILE [TARGET_FILE]                      # 编译 Prompt.md 成能够提交给 ChatGPT API 的 messages. 默认输出为 <同文件名>.json
  luogu generate JSON_FILE [PROMPT_FILE]                     # 根据 ChatGPT messages JSON 来生成 Prompt.md
  luogu run PROMPT_FILE                                      # 编译 Prompt.md 成能够提交给 ChatGPT API 的 messages. 默认输出为 <同文件名>.json
  luogu test [PROMPT_FILE] [TEST_FILE]                       # 测试 Prompt 文件
  luogu version                                              # 打印版本
```

你可以在项目目录的.env中设置下面的环境变量，或者直接系统设置
```
OPENAI_ACCESS_TOKEN=zheshiyigetoken
OPENAI_TEMPERATURE=0.7
OPENAI_LIMIT_HISTORY=6
```

prompt.md 示例
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

如果需要处理历史记录的是否进入上下文可以使用，在 prompt.md写入


@callback
```ruby
if assistant_message =~ /```ruby/
  puts "记录本次记录"
  self.push_history(user_message, assistant_message)
else
  puts "抛弃本次记录"
end
```


### 进入run模式
- save 保存对话
- row history  查看对话历史
- history 查看当前上下文
- exit 退出

## 插件模式
OpenStruct.new(request_params: params)
OpenStruct.new(user_input: user_message)
OpenStruct.new(request_messages: messages)
OpenStruct.new(user_input: user_message, response_message: assistant_message)

## MIT 协议