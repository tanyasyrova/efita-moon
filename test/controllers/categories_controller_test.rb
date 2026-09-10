require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "show opens active category by slug" do
    get catalog_category_path(categories(:chokers).slug)

    assert_response :success
    assert_equal "/catalog/chokers", catalog_category_path(categories(:chokers).slug)
    assert_select ".catalog-page"
    assert_select "h1", "Чокеры"
  end

  test "show returns not found for unknown slug" do
    get catalog_category_path("unknown-category")

    assert_response :not_found
  end

  test "show returns not found for inactive category" do
    get catalog_category_path(categories(:anklets).slug)

    assert_response :not_found
  end

  test "show includes only published products from selected category" do
    get catalog_category_path(categories(:chokers).slug)

    assert_match products(:moonlight_choker).title, response.body
    assert_match products(:silver_moon_choker).title, response.body
    assert_match products(:sold_out_choker).title, response.body
    assert_select ".catalog-grid"
    assert_select ".product-card"
    assert_no_match products(:quiet_shine_earrings).title, response.body
    assert_no_match products(:pearl_earrings).title, response.body
  end

  test "show displays all statuses for category products" do
    get catalog_category_path(categories(:chokers).slug)

    assert_match "В наличии", response.body
    assert_match "Доступен к заказу", response.body
    assert_match "Нет в наличии", response.body
    assert_select ".product-status"
  end

  test "show links products by slug" do
    get catalog_category_path(categories(:chokers).slug)

    assert_select "a[href=?]", product_path(products(:moonlight_choker).slug), text: products(:moonlight_choker).title
    assert_select "a[href=?]", product_path(products(:silver_moon_choker).slug), text: products(:silver_moon_choker).title
  end

  test "show renders empty state for active category without products" do
    category = Category.create!(
      name: "Пустая категория",
      slug: "empty-category",
      position: 99,
      active: true
    )

    get catalog_category_path(category.slug)

    assert_response :success
    assert_match "В этой категории пока нет украшений.", response.body
  end
end
