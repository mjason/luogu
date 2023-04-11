module Luogu
  class Plugin
    attr_reader :before_input_proc, :before_save_history_proc, :after_input_proc, :after_save_history_proc,
     :setup_proc, :before_request_proc, :after_request_proc

    def initialize(plugin_file_path)
      @plugin_file_path = plugin_file_path

      @before_input_proc = nil
      @before_save_history_proc = nil

      @after_input_proc = nil
      @after_save_history_proc = nil

      @setup_proc = nil
    end

    def before_input(&block)
      @before_input_proc = block
    end

    def before_save_history(&block)
      @before_save_history_proc = block
    end

    def after_input(&block)
      @after_input_proc = block
    end

    def after_save_history(&block)
      @after_save_history_proc = block
    end

    def setup(&block)
      @setup_proc = block
    end

    def before_request(&block)
      @before_request_proc = block
    end

    def after_request(&block)
      @after_request_proc = block
    end

    def load()
      self.instance_eval File.read(@plugin_file_path)
      self
    end
    
  end
end