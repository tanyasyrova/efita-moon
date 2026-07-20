categories = [
  { position: 1, name: "Чокеры", slug: "chokers", active: true },
  { position: 2, name: "Колье", slug: "necklaces", active: true },
  { position: 3, name: "Сотуары", slug: "sautoirs", active: true },
  { position: 4, name: "Серьги", slug: "earrings", active: true },
  { position: 5, name: "Браслеты", slug: "bracelets", active: true },
  { position: 6, name: "Анклеты", slug: "anklets", active: true }
]

categories.each do |attributes|
  Category.find_or_create_by!(slug: attributes.fetch(:slug)) do |category|
    category.name = attributes.fetch(:name)
    category.position = attributes.fetch(:position)
    category.active = attributes.fetch(:active)
  end
end

puts "Catalog categories seeded: #{categories.size}"
