class AgentSerializer
  def self.render(agent)
    { id: agent.id, name: agent.name, email: agent.email }
  end
end
