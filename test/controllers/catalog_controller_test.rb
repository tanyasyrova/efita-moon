require "test_helper"

class CatalogControllerTest < ActionDispatch::IntegrationTest
  test "index returns success and renders catalog heading" do
    get catalog_path

    assert_response :success
    assert_select ".catalog-page"
    assert_select ".catalog-page__intro"
    assert_select "h1", "Каталог"
  end

  test "index shows active categories and hides inactive categories" do
    get catalog_path

    assert_select ".category-nav[aria-label='Категории каталога']"
    assert_select "a[href=?]", catalog_category_path(categories(:neck).slug), text: /На шею/
    assert_select "a[href=?]", catalog_category_path(categories(:ears).slug), text: /На уши/
    assert_match "Чокеры · Колье · Сотуары", response.body
    assert_no_match categories(:archive).name, response.body
  end

  test "index does not render empty category subtitle" do
    categories(:bags).update!(subtitle: nil)

    get catalog_path

    assert_response :success
    assert_select "a[href=?] .category-nav__subtitle", catalog_category_path(categories(:bags).slug), count: 0
  end

  test "index shows published products from active categories only" do
    get catalog_path

    assert_match products(:moonlight_choker).title, response.body
    assert_match products(:silver_moon_choker).title, response.body
    assert_match products(:sold_out_choker).title, response.body
    assert_match products(:pearl_earrings).title, response.body
    assert_select ".catalog-grid"
    assert_select ".product-card"
    assert_no_match products(:quiet_shine_earrings).title, response.body
    assert_no_match products(:hidden_anklet).title, response.body
  end

  test "index shows all public statuses" do
    get catalog_path

    assert_match "В наличии", response.body
    assert_match "Доступен к заказу", response.body
    assert_match "Нет в наличии", response.body
    assert_select ".product-status"
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
