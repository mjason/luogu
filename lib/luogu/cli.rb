module Luogu
  module_function
  def cli
    options = {}
    subcommands = {}

    OptionParser.new do |opts|
      opts.banner = "Usage: luogu [command]"

      opts.on("-h", "--help", "Prints help") do
        puts """
        luogu build <file> -> 编译prompt
        luogu run <file> -> 测试 prompt
        luogu gen <file> <target> -> 根据 json 生成 prompt 文件
        """
        exit
      end

    end.parse!

   
    subcommands['build'] = Proc.new do |args|
      data = PromptParser.new(args.first).to_json
      target_path = args[1] || "./prompt.json"
      File.open(target_path, 'w') do |f|
        f.write(data)
      end
    end

    subcommands['run'] = Proc.new do |args|
      chatgpt = ChatGPT.new(args.first)
      chatgpt.run
    end

    subcommands['gen'] = Proc.new do |args|
      json = JSON.parse File.read(args.first), symbolize_names: true   
      chatgpt = ChatGPT.save(json, args.last)
    end

    if subcommands.key?(ARGV.first)
      subcommands[ARGV.first].call(ARGV[1..-1])
    else
      puts "Invalid command. Use -h or --help for usage information."
    end

  end
end