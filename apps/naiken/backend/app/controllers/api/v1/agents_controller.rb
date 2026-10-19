module Api
  module V1
    class AgentsController < ApplicationController
      def index
        agents = Agent.order(:id)
        render json: { data: agents.map { AgentSerializer.render(it) } }
      end
    end
  end
end
