module Luogu
  class AgentRunner
    attr_accessor :system_prompt_template, :user_input_prompt_template
    attr_reader :session

    def initialize(system_prompt_template: nil, user_input_prompt_template: nil, tools_response_prompt_template: nil, session: Session.new)
      @system_prompt_template = system_prompt_template || load_system_prompt_default_template
      @user_input_prompt_template = user_input_prompt_template || load_user_input_prompt_default_template
      @tools_response_prompt_template = tools_response_prompt_template || load_tools_response_prompt_default

      @agents = []
      @session = session

      @chatgpt_request_body = Luogu::OpenAI::ChatRequestBody.new(temperature: 0)
      @chatgpt_request_body.stop = ["\nObservation:", "\n\tObservation:"]
      @limit_history = ENV.fetch('OPENAI_LIMIT_HISTORY', '6').to_i * 2
      @histories = HistoryQueue.new @limit_history

      @last_user_input = ''
      @tools_response = []
    end

    def openai_configuration(&block)
      block.call @chatgpt_request_body
    end

    def register(agent)
      raise AssertionError.new('agent must inherit from Luogu::Agent') unless agent < Agent
      @agents << agent
      self
    end

    def request(messages)
      @chatgpt_request_body.messages = messages
      response = client.chat(params: @chatgpt_request_body.to_h)
      if response.code == 200
        response.parse
      else
        logger.error response.body.to_s
        raise OpenAI::RequestError
      end
    end

    def user_input_prompt_template
      @user_input_prompt_template.result binding
    end

    def system_prompt_template
      @system_prompt_template.result binding
    end

    def tools_response_prompt_template
      @tools_response_prompt_template.result binding
    end

    def find_final_answer(content)
      if content.is_a?(Hash) && content['action'] == 'Final Answer'
        content['action_input']
      elsif content.is_a?(Array)
        result = content.find { |element| element["action"] == "Final Answer" }
        if result
          result["action_input"]
        else
          nil
        end
      else
        nil
      end
    end

    def find_and_save_final_answer(content)
      if answer = self.find_final_answer(content)
        self.save_history(answer)
        answer
      else
        nil
      end
    end

    def save_history(finnal_answer)
      @histories.enqueue({role: "user", content: @last_user_input})
      @histories.enqueue({role: "assistant", content: finnal_answer})
    end

    def parse_json(markdown)
      json_regex = /```json(.+?)```/im
      json_blocks = markdown.scan(json_regex)
      result_json = nil
      json_blocks.each do |json_block|
        json_string = json_block[0]
        result_json = JSON.parse(json_string)
      end
      
      if result_json.nil?
        JSON.parse markdown
      else
        result_json
      end
    end

    def create_messages(messages)
      [{role: "system", content: self.system_prompt_template}] + @histories.to_a + messages
    end

    def request_chat(messages)
      logger.debug "request chat: #{messages}"
      response = request messages
      content = self.parse_json response.dig("choices", 0, "message", "content")
      logger.debug content
      if answer = self.find_and_save_final_answer(content)
        logger.info "finnal answer: #{answer}"
      elsif content.is_a?(Array)
        self.run_agents(content, messages)
      end
    end

    def chat(message)
      @last_user_input = message
      messages = self.create_messages([{role: "user", content: self.user_input_prompt_template}])
      self.request_chat(messages)
    end

    def run_agents(agents, _messages_)
      if answer = self.find_and_save_final_answer(agents)
        logger.info "finnal answer: #{answer}"
        return
      end
      @tools_response = []
      agents.each do |agent|
        agent_class = Module.const_get(agent['action'])
        logger.info "running #{agent_class}"
        response = agent_class.new.call(agent['action_input'])
        @tools_response << {name: agent['action'], response: response}
      end
      messages = _messages_ + [{role: "assistant", content: agents.to_json}, {role: "user", content: self.tools_response_prompt_template}]
      self.request_chat messages
    end

    private
    def load_system_prompt_default_template
      PromptTemplate.load_template('agent_system.md.erb')
    end

    def load_user_input_prompt_default_template
      PromptTemplate.load_template('agent_input.md.erb')
    end

    def load_tools_response_prompt_default
      PromptTemplate.load_template('agent_tool_input.md.erb')
    end
  end

  class AssertionError < StandardError
  end
end