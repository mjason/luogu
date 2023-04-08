module Luogu
  class HistoryQueue
    def initialize(max_size = 12)
      @queue = []
      @max_size = max_size
    end
  
    def enqueue(element)
      if @queue.size == @max_size
        @queue.shift
      end
      @queue << element
    end
  
    def dequeue
      @queue.shift
    end
  
    def size
      @queue.size
    end

    def to_a
      @queue
    end
  
    def to_json
      JSON.pretty_generate @queue
    end
  end
end