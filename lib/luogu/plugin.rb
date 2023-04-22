module Luogu
  class Plugin
    attr_reader :plugin_file_path, :before_input_proc, :before_save_history_proc, :after_input_proc,
                :after_save_history_proc, :setup_proc, :before_request_proc, :after_request_proc

    # 定义一个元编程方法来动态定义属性设置方法
    def self.define_attr_setter(attr_name)
      define_method("#{attr_name}") do |&block|
        instance_variable_set("@#{attr_name}_proc", block)
      end
    end

    def initialize(plugin_file_path)
      @plugin_file_path = plugin_file_path
    end

    # 使用元编程方法来动态定义属性设置方法
    define_attr_setter :before_input
    define_attr_setter :before_save_history
    define_attr_setter :after_input
    define_attr_setter :after_save_history
    define_attr_setter :setup
    define_attr_setter :before_request
    define_attr_setter :after_request

    def load()
      self.instance_eval File.read(plugin_file_path)
      self
    end

    def run(method_name: nil, llm: nil, context: nil, &block)
      method_name = "#{method_name}_proc".to_sym
      if send(method_name).respond_to?(:call)
        rt = send(method_name).call(llm, context)
        block.call(rt) unless block.nil?
        rt
      end
    end
  end
end
