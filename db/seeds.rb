categories = [
  { position: 0, name: "На шею", slug: "neck", subtitle: "Чокеры · Колье · Сотуары", active: true },
  { position: 1, name: "На уши", slug: "ears", subtitle: "Серьги", active: true },
  { position: 2, name: "На руки", slug: "hands", subtitle: "Браслеты", active: true },
  { position: 3, name: "На ноги", slug: "ankles", subtitle: "Анклеты", active: true },
  { position: 4, name: "На сумку", slug: "bags", subtitle: "Обвесы · Подвески", active: true }
]

categories.each do |attributes|
  category = Category.find_or_initialize_by(slug: attributes.fetch(:slug))
  category.assign_attributes(attributes)
  category.save!
end

puts "Catalog categories seeded: #{categories.size}"
