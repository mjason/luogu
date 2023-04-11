module Luogu
  module CLI
    module Commands
      extend Dry::CLI::Registry
      
      class Version < Dry::CLI::Command
        desc "打印版本"

        def call(*)
          puts Luogu::VERSION
        end
      end

      class Build < Dry::CLI::Command

        desc "编译 Prompt.md 成能够提交给 ChatGPT API 的 messages. 默认输出为 <同文件名>.json"
        argument :prompt_file, type: :string, required: true, deec: "Prompt文件, 使用markdown书写"
        argument :target_file, type: :string, required: false, deec: "输出 JSON 文件"

        def call(prompt_file: nil, target_file: nil, **)
          target_file ||=  prompt_file.sub(File.extname(prompt_file), ".json")
          data = PromptParser.new(prompt_file).to_json
          File.open(target_file, 'w') do |f|
            f.write(data)
          end
        end

      end

      class Run < Dry::CLI::Command

        desc "编译 Prompt.md 成能够提交给 ChatGPT API 的 messages. 默认输出为 <同文件名>.json"
        argument :prompt_file, type: :string, required: true, desc: "Prompt文件, 使用markdown书写"
        option :out, type: :string, default: ".", desc: "保存历史时存放的目录，默认为当前目录"
        option :plugin, type: :string, desc: "运行的时候载入对应的插件"

        def call(prompt_file: nil, **options)
          chatgpt = ChatGPT.new(prompt_file, options.fetch(:out), options.fetch(:plugin, nil))
          chatgpt.run
        end

      end

      class Generate < Dry::CLI::Command

        desc "根据 ChatGPT messages JSON 来生成 Prompt.md"
        argument :json_file, type: :string, required: true, deec: "ChatGPT 生成的 messages json 文件"
        argument :prompt_file, type: :string, required: false, deec: "要输出的Prompt文件路径, 默认生成 <同名>.md"

        def call(json_file: nil, prompt_file: nil, **)
          json = JSON.parse(File.read(json_file), symbolize_names: true)
          prompt_file ||=  json_file.sub(File.extname(json_file), ".md")

          chatgpt = ChatGPT.save(json, prompt_file)
        end

      end

      class Test < Dry::CLI::Command

        desc "测试 Prompt 文件"
        argument :prompt_file, type: :string, require: true, desc: "输出 Prompt 文件"
        argument :test_file, type: :string, require: false, desc: "测试文件, 使用 YAML 文件, 一个字符串数组。默认为 同名.test.yml"
        option :out, type: :string, default: ".", desc: "保存测试历史时存放的目录，默认为当前目录"
        option :plugin, type: :string, desc: "运行的时候载入对应的插件"

        def call(prompt_file: nil, test_file:nil, **options)
          test_file ||= prompt_file.sub(File.extname(prompt_file), ".test.yml")

          chatgpt = ChatGPT.new(prompt_file, options.fetch(:out), options.fetch(:plugin, nil))
          messages = YAML.load_file(test_file)
          chatgpt.playload messages
        end

      end

      register "version", Version, aliases: ["v", "-v", "--version"]
      register "build", Build, aliases: ["b"]
      register "run", Run, aliases: ["r"]
      register "generate", Generate, aliases: ["g"]
      register "test", Test, aliases: ["t"]

    end
  end

  module_function
  def cli
    Dry::CLI.new(Luogu::CLI::Commands).call
  end
end
