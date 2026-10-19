class PropertySerializer
  def self.render(property)
    {
      id: property.id,
      name: property.name,
      address: property.address,
      price: property.price,
      layout: property.layout,
      # decimal はJSONで文字列になるため、数値で返す
      floor_area: property.floor_area&.to_f,
      built_year: property.built_year,
      nearest_station: property.nearest_station,
      walk_minutes: property.walk_minutes,
      status: property.status,
      note: property.note,
      created_at: property.created_at,
      updated_at: property.updated_at
    }
  end
end
