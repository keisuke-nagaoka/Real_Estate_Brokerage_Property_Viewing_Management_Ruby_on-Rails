class PropertySerializer
  def self.render(property)
    {
      id: property.id,
      name: property.name,
      prefecture: property.prefecture,
      city: property.city,
      address_line: property.address_line,
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
      # 1枚目を一覧のカバー写真として使う
      photos: property.photos.map do |photo|
        {
          id: photo.id,
          filename: photo.filename.to_s,
          url: StoragePath.for(photo.variant(:large)),
          thumbnail_url: StoragePath.for(photo.variant(:thumb))
        }
      end,
      created_at: property.created_at,
      updated_at: property.updated_at
    }
  end
end
