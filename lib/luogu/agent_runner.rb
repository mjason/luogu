# frozen_string_literal: true

module Luogu
  class AgentRunner < Base
    setting :templates do
      setting :system, default: PromptTemplate.load_template('agent_system.md.erb')
      setting :user, default: PromptTemplate.load_template('agent_input.md.erb')
      setting :tool, default: PromptTemplate.load_template('agent_tool_input.md.erb')
    end

    setting :run_agent_retries, default: Application.config.run_agent_retries
    setting :mode, default: :agent # route 路由模式 agent 代理模式
    setting :route_mode_response_handle, default: ->(tool_responses) { tool_responses&.first.fetch(:response, nil) }

    setting :provider do
      setting :parameter_model, default: ->() {
        OpenAI::ChatRequestParams.new(
          model: 'gpt-3.5-turbo',
          stop: %W[\nObservation: \n\tObservation:],
          temperature: 0
        )
      }
      setting :request, default: ->(params) { OpenAI.chat(params: params) }
      setting :parse, default: ->(response) { OpenAI.chat_response_handle(response) }
      setting :find_final_answer, default: ->(content) { OpenAI.find_final_answer(content) }
      setting :history_limit, default: Application.config.openai.history_limit
    end

    attr_reader :request_params, :agents, :histories
    def initialize()
      @request_params = provider.parameter_model.call
      @histories = HistoryQueue.new provider.history_limit
      @last_user_input = ''
      @agents = {}
      @tools_response = []
    end

    def provider
      config.provider
    end

    def templates
      config.templates
    end

    def register(agent)
      raise AssertionError.new('agent must inherit from Luogu::Agent') unless agent < Agent
      @agents[agent.agent_name] = agent
      self
    end

    def run(text)
      @last_user_input = text
      messages = create_messages(
        [{role: "user", content: templates.user.result(binding)}]
      )
      request(messages)
    end
    alias_method :chat, :run

    def create_messages(messages)
      if templates.system.nil?
        @histories.to_a + messages
      else
        [
          { role: "system", content: templates.system.result(binding) }
        ] + @histories.to_a + messages
      end
    end

    def request(messages, run_agent_retries: 0)
      logger.debug "request chat: #{messages}"
      @request_params.messages = messages
      response = provider.request.call(@request_params.to_h)
      unless response.code == 200
        logger.error response.body.to_s
        raise RequestError, response.body.to_s
      end

      begin
        content = Luogu.wrap_array(provider.parse.call(response))
      rescue => error
        logger.error error.message
        return "error! #{error.message}"
      end


      logger.debug content

      if (answer = self.find_and_save_final_answer(content))
        logger.info "final answer: #{answer}"
        answer
      else
        run_agents(content, messages, run_agent_retries: run_agent_retries)
      end
    end

    def find_and_save_final_answer(content)
      if (answer = provider.find_final_answer.call(content))
        @histories.enqueue({role: "user", content: @last_user_input})
        @histories.enqueue({role: "assistant", content: answer})
        answer
      else
        nil
      end
    end

    def run_agents(agents, _messages_, run_agent_retries: 0)
      return if run_agent_retries > config.run_agent_retries
      run_agent_retries += 1
      if (answer = find_and_save_final_answer(agents))
        logger.info "final answer: #{answer}"
        return
      end
      @tools_response = []
      agents.each do |agent|
        agent_class = @agents[agent['action']]
        logger.info "#{run_agent_retries} running #{agent_class} input: #{agent['action_input']}"
        response = agent_class.new(@last_user_input).call(agent['action_input'])
        @tools_response << {name: agent['action'], response: response}
      end
      messages = _messages_ + [
        { role: "assistant", content: agents.to_json },
        { role: "user", content: templates.tool.result(binding) }
      ]
      if config.mode == :agent
        request messages, run_agent_retries: run_agent_retries
      else
        config.route_mode_response_handle.call @tools_response
      end
    end

  end
end
