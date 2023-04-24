# frozen_string_literal: true

module Luogu
  def println(message)
    if system("which glow > /dev/null 2>&1")
      system("echo #{Shellwords.escape(message)} | glow -")
    else
      puts message
    end
  end

  def wrap_array(obj)
    if obj.is_a?(Array)
      obj
    else
      [obj]
    end
  end

  module_function :println, :wrap_array
end