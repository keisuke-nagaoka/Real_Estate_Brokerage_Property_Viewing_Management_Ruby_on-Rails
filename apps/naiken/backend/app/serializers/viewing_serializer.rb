class ViewingSerializer
  def self.render(viewing)
    {
      id: viewing.id,
      starts_at: viewing.starts_at,
      ends_at: viewing.ends_at,
      status: viewing.status,
      note: viewing.note,
      customer: { id: viewing.customer.id, name: viewing.customer.name },
      property: { id: viewing.property.id, name: viewing.property.name, address: viewing.property.address },
      agent: { id: viewing.agent.id, name: viewing.agent.name },
      created_at: viewing.created_at,
      updated_at: viewing.updated_at
    }
  end
end
