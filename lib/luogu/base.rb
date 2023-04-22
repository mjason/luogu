# frozen_string_literal: true

module Luogu

  class Base
    extend Dry::Configurable

    def logger
      Application.logger
    end

    def config
      self.class.config
    end
  end

end
