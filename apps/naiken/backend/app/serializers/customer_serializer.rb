class CustomerSerializer
  def self.render(customer)
    {
      id: customer.id,
      name: customer.name,
      name_kana: customer.name_kana,
      email: customer.email,
      phone: customer.phone,
      budget_max: customer.budget_max,
      desired_area: customer.desired_area,
      note: customer.note,
      agent: AgentSerializer.render(customer.agent),
      created_at: customer.created_at,
      updated_at: customer.updated_at
    }
  end
end
