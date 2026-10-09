require "test_helper"

module Admin
  class CategoriesControllerTest < ActionDispatch::IntegrationTest
    test "index requires authentication" do
      without_admin_credentials do
        get admin_categories_path
      end

      assert_response :unauthorized
    end

    test "index allows correct credentials" do
      with_admin_credentials do
        get admin_categories_path, headers: admin_auth_headers
      end

      assert_response :success
    end

    test "index rejects wrong credentials" do
      with_admin_credentials do
        get admin_categories_path, headers: admin_auth_headers(password: "wrong")
      end

      assert_response :unauthorized
    end

    test "index shows active and inactive categories with controls" do
      with_admin_credentials do
        get admin_categories_path, headers: admin_auth_headers
      end

      assert_response :success
      assert_match categories(:neck).name, response.body
      assert_match categories(:neck).subtitle, response.body
      assert_match categories(:archive).name, response.body
      assert_match "Активна", response.body
      assert_match "Неактивна", response.body
      assert_select "a[href=?]", new_admin_category_path, text: "Новая категория"
      assert_select "a[href=?]", edit_admin_category_path(categories(:neck)), text: "Редактировать"
      assert_select "form[action=?]", admin_category_path(categories(:neck))
    end

    test "creates valid category" do
      assert_difference("Category.count", 1) do
        with_admin_credentials do
          post admin_categories_path,
               params: { category: valid_category_params },
               headers: admin_auth_headers
        end
      end

      assert_redirected_to admin_categories_path
      category = Category.find_by!(slug: "admin-category")
      assert_equal "Тестовая подпись", category.subtitle
    end

    test "does not create invalid category" do
      assert_no_difference("Category.count") do
        with_admin_credentials do
          post admin_categories_path,
               params: { category: valid_category_params(name: "", slug: "Bad Slug") },
               headers: admin_auth_headers
        end
      end

      assert_response :unprocessable_entity
      assert_match "Проверьте поля формы", response.body
    end

    test "creates category without subtitle" do
      assert_difference("Category.count", 1) do
        with_admin_credentials do
          post admin_categories_path,
               params: { category: valid_category_params(slug: "category-without-subtitle", subtitle: "") },
               headers: admin_auth_headers
        end
      end

      assert_redirected_to admin_categories_path
      assert_equal "", Category.find_by!(slug: "category-without-subtitle").subtitle
    end

    test "updates category" do
      category = categories(:ears)

      with_admin_credentials do
        patch admin_category_path(category),
              params: {
                category: valid_category_params(
                  name: "Новая категория",
                  slug: "new-category",
                  subtitle: "Новая подпись",
                  position: 10,
                  active: "0"
                )
              },
              headers: admin_auth_headers
      end

      assert_redirected_to admin_categories_path
      category.reload
      assert_equal "Новая категория", category.name
      assert_equal "new-category", category.slug
      assert_equal "Новая подпись", category.subtitle
      assert_equal 10, category.position
      assert_not category.active?
    end

    test "destroys empty category" do
      category = Category.create!(name: "Пустая", slug: "empty-category", position: 20, active: true)

      assert_difference("Category.count", -1) do
        with_admin_credentials do
          delete admin_category_path(category), headers: admin_auth_headers
        end
      end

      assert_redirected_to admin_categories_path
    end

    test "does not destroy category with products" do
      category = categories(:neck)

      assert_no_difference("Category.count") do
        assert_no_difference("Product.count") do
          with_admin_credentials do
            delete admin_category_path(category), headers: admin_auth_headers
          end
        end
      end

      assert_redirected_to admin_categories_path
      assert Category.exists?(category.id)
      assert_match "Cannot delete record because dependent products exist", flash[:alert]
    end

    private

    def with_admin_credentials
      previous_username = ENV["ADMIN_USERNAME"]
      previous_password = ENV["ADMIN_PASSWORD"]
      ENV["ADMIN_USERNAME"] = "admin"
      ENV["ADMIN_PASSWORD"] = "secret"
      yield
    ensure
      ENV["ADMIN_USERNAME"] = previous_username
      ENV["ADMIN_PASSWORD"] = previous_password
    end

    def without_admin_credentials
      previous_username = ENV["ADMIN_USERNAME"]
      previous_password = ENV["ADMIN_PASSWORD"]
      ENV.delete("ADMIN_USERNAME")
      ENV.delete("ADMIN_PASSWORD")
      yield
    ensure
      ENV["ADMIN_USERNAME"] = previous_username
      ENV["ADMIN_PASSWORD"] = previous_password
    end

    def admin_auth_headers(username: "admin", password: "secret")
      {
        "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
      }
    end

    def valid_category_params(attributes = {})
      {
        name: "Админ категория",
        slug: "admin-category",
        subtitle: "Тестовая подпись",
        position: 3,
        active: "1"
      }.merge(attributes)
    end
  end
end
