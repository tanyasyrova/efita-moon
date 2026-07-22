require "test_helper"

class CatalogControllerTest < ActionDispatch::IntegrationTest
  test "index returns success and renders catalog heading" do
    get catalog_path

    assert_response :success
    assert_select "h1", "Каталог"
  end

  test "index shows active categories and hides inactive categories" do
    get catalog_path

    assert_select "nav[aria-label='Категории каталога']"
    assert_select "a[href=?]", catalog_category_path(categories(:chokers).slug), text: "Чокеры"
    assert_select "a[href=?]", catalog_category_path(categories(:earrings).slug), text: "Серьги"
    assert_no_match categories(:anklets).name, response.body
  end

  test "index shows published products from active categories only" do
    get catalog_path

    assert_match products(:moonlight_choker).title, response.body
    assert_match products(:silver_moon_choker).title, response.body
    assert_match products(:sold_out_choker).title, response.body
    assert_match products(:pearl_earrings).title, response.body
    assert_no_match products(:quiet_shine_earrings).title, response.body
    assert_no_match products(:hidden_anklet).title, response.body
  end

  test "index shows all public statuses" do
    get catalog_path

    assert_match "В наличии", response.body
    assert_match "Доступен к заказу", response.body
    assert_match "Нет в наличии", response.body
  end

  test "index links products by slug" do
    get catalog_path

    assert_select "a[href=?]", product_path(products(:moonlight_choker).slug), text: products(:moonlight_choker).title
    assert_select "a[href=?]", product_path(products(:silver_moon_choker).slug), text: products(:silver_moon_choker).title
  end

  test "index renders empty states" do
    Product.delete_all
    Category.delete_all

    get catalog_path

    assert_response :success
    assert_match "Категории пока не добавлены.", response.body
    assert_match "В каталоге пока нет украшений.", response.body
  end
end
