require "test_helper"

module Admin
  class ProductsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @category = categories(:neck)
      @other_category = categories(:ears)
    end

    test "index requires authentication" do
      without_admin_credentials do
        get admin_products_path
      end

      assert_response :unauthorized
    end

    test "index rejects wrong credentials" do
      with_admin_credentials do
        get admin_products_path, headers: admin_auth_headers(password: "wrong")
      end

      assert_response :unauthorized
    end

    test "index allows correct credentials" do
      with_admin_credentials do
        get admin_products_path, headers: admin_auth_headers
      end

      assert_response :success
    end

    test "index shows published and unpublished products" do
      with_admin_credentials do
        get admin_products_path, headers: admin_auth_headers
      end

      assert_response :success
      assert_match products(:moonlight_choker).title, response.body
      assert_match products(:quiet_shine_earrings).title, response.body
      assert_match products(:moonlight_choker).category.name, response.body
      assert_match "В наличии", response.body
      assert_match "Опубликован", response.body
      assert_match "Скрыт", response.body
      assert_select "a[href=?]", new_admin_product_path, text: "Новый товар"
      assert_select "a[href=?]", edit_admin_product_path(products(:moonlight_choker)), text: "Редактировать"
      assert_select "form[action=?]", admin_product_path(products(:moonlight_choker))
    end

    test "creates valid product" do
      assert_difference("Product.count", 1) do
        with_admin_credentials do
          post admin_products_path,
               params: { product: valid_product_params },
               headers: admin_auth_headers
        end
      end

      product = Product.order(:created_at).last
      assert_redirected_to edit_admin_product_path(product)
      assert_equal @category, product.category
      assert_equal "made_to_order", product.status
      assert_not product.published?
    end

    test "does not create invalid product" do
      assert_no_difference("Product.count") do
        with_admin_credentials do
          post admin_products_path,
               params: { product: valid_product_params(title: "") },
               headers: admin_auth_headers
        end
      end

      assert_response :unprocessable_entity
      assert_match "Проверьте поля формы", response.body
    end

    test "updates product fields" do
      product = products(:moonlight_choker)

      with_admin_credentials do
        patch admin_product_path(product),
              params: {
                product: valid_product_params(
                  title: "Обновлённое колье",
                  category_id: @other_category.id,
                  price: "3450.50",
                  status: "unavailable",
                  published: "0"
                )
              },
              headers: admin_auth_headers
      end

      assert_redirected_to edit_admin_product_path(product)
      product.reload
      assert_equal "Обновлённое колье", product.title
      assert_equal @other_category, product.category
      assert_equal 3450.50.to_d, product.price
      assert_equal "unavailable", product.status
      assert_not product.published?
    end

    test "destroys product and product image records" do
      product = create_product
      create_product_image(product: product)

      assert_difference("Product.count", -1) do
        assert_difference("ProductImage.count", -1) do
          with_admin_credentials do
            delete admin_product_path(product), headers: admin_auth_headers
          end
        end
      end

      assert_redirected_to admin_products_path
    end

    test "creates product with multiple uploaded images and sequential positions" do
      assert_difference("ProductImage.count", 3) do
        with_admin_credentials do
          post admin_products_path,
               params: {
                 product: valid_product_params.merge(
                   uploaded_images: [
                     fixture_file_upload("test.jpg", "image/jpeg"),
                     fixture_file_upload("test.png", "image/png"),
                     fixture_file_upload("test.webp", "image/webp")
                   ]
                 )
               },
               headers: admin_auth_headers
        end
      end

      product = Product.order(:created_at).last
      assert_equal [ 0, 1, 2 ], product.product_images.pluck(:position)
      assert product.product_images.all? { |product_image| product_image.image.attached? }
    end

    test "appends uploaded image at max position plus one" do
      product = create_product
      create_product_image(product: product, position: 0)
      create_product_image(product: product, position: 3)

      with_admin_credentials do
        patch admin_product_path(product),
              params: {
                product: valid_product_params.merge(
                  uploaded_images: [ fixture_file_upload("test.png", "image/png") ]
                )
              },
              headers: admin_auth_headers
      end

      assert_redirected_to edit_admin_product_path(product)
      assert_equal [ 0, 3, 4 ], product.product_images.reload.pluck(:position)
    end

    test "updates existing image positions" do
      product = create_product
      first_image = create_product_image(product: product, position: 0)
      second_image = create_product_image(product: product, filename: "test.png", content_type: "image/png", position: 1)

      with_admin_credentials do
        patch admin_product_path(product),
              params: {
                product: valid_product_params,
                product_images: {
                  first_image.id => { position: 4 },
                  second_image.id => { position: 1 }
                }
              },
              headers: admin_auth_headers
      end

      assert_redirected_to edit_admin_product_path(product)
      assert_equal [ second_image.id, first_image.id ], product.product_images.reload.map(&:id)
      assert_equal 4, first_image.reload.position
    end

    test "deletes selected image and keeps product" do
      product = create_product
      deleted_image = create_product_image(product: product, position: 0)
      kept_image = create_product_image(product: product, filename: "test.png", content_type: "image/png", position: 1)

      assert_difference("ProductImage.count", -1) do
        with_admin_credentials do
          patch admin_product_path(product),
                params: {
                  product: valid_product_params,
                  product_images: {
                    deleted_image.id => { position: 0, delete: "1" },
                    kept_image.id => { position: 1 }
                  }
                },
                headers: admin_auth_headers
        end
      end

      assert_redirected_to edit_admin_product_path(product)
      assert Product.exists?(product.id)
      assert_not ProductImage.exists?(deleted_image.id)
      assert ProductImage.exists?(kept_image.id)
    end

    test "does not delete image from another product" do
      product = create_product
      other_product = create_product(slug: "other-admin-product-#{SecureRandom.hex(4)}")
      foreign_image = create_product_image(product: other_product)

      assert_no_difference("ProductImage.count") do
        with_admin_credentials do
          patch admin_product_path(product),
                params: {
                  product: valid_product_params,
                  product_images: {
                    foreign_image.id => { position: 0, delete: "1" }
                  }
                },
                headers: admin_auth_headers
        end
      end

      assert_redirected_to edit_admin_product_path(product)
      assert ProductImage.exists?(foreign_image.id)
    end

    test "invalid uploaded image rolls back product update" do
      product = create_product(title: "До обновления")

      assert_no_difference("ProductImage.count") do
        with_admin_credentials do
          patch admin_product_path(product),
                params: {
                  product: valid_product_params(title: "После обновления").merge(
                    uploaded_images: [ invalid_uploaded_file ]
                  )
                },
                headers: admin_auth_headers
        end
      end

      assert_response :unprocessable_entity
      assert_equal "До обновления", product.reload.title
      assert_match "must be a JPEG, PNG, or WebP file", response.body
    end

    test "one invalid upload rolls back all uploaded images" do
      product = create_product(title: "До загрузки")

      assert_no_difference("ProductImage.count") do
        with_admin_credentials do
          patch admin_product_path(product),
                params: {
                  product: valid_product_params(title: "После загрузки").merge(
                    uploaded_images: [
                      fixture_file_upload("test.jpg", "image/jpeg"),
                      fixture_file_upload("test.png", "image/png"),
                      invalid_uploaded_file
                    ]
                  )
                },
                headers: admin_auth_headers
        end
      end

      assert_response :unprocessable_entity
      assert_equal "До загрузки", product.reload.title
      assert_match "must be a JPEG, PNG, or WebP file", response.body
    end

    test "invalid image position rolls back product update" do
      product = create_product(title: "До обновления")
      product_image = create_product_image(product: product, position: 0)

      with_admin_credentials do
        patch admin_product_path(product),
              params: {
                product: valid_product_params(title: "После обновления"),
                product_images: {
                  product_image.id => { position: -1 }
                }
              },
              headers: admin_auth_headers
      end

      assert_response :unprocessable_entity
      assert_equal "До обновления", product.reload.title
      assert_equal 0, product_image.reload.position
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

    def valid_product_params(attributes = {})
      {
        title: "Админ товар",
        slug: "admin-product-#{SecureRandom.hex(4)}",
        category_id: @category.id,
        description: "Описание товара.",
        size: "36 см",
        materials: "Гематит",
        price: "2500.00",
        status: "made_to_order",
        published: "0"
      }.merge(attributes)
    end

    def create_product(attributes = {})
      Product.create!({
        category: @category,
        title: "Админ товар #{SecureRandom.hex(4)}",
        slug: "admin-product-#{SecureRandom.hex(4)}",
        description: "Описание товара.",
        price: 2500,
        status: "available",
        published: true
      }.merge(attributes))
    end

    def create_product_image(attributes = {})
      filename = attributes.delete(:filename) || "test.jpg"
      content_type = attributes.delete(:content_type) || "image/jpeg"

      ProductImage.new({
        product: create_product,
        position: 0
      }.merge(attributes)).tap do |product_image|
        product_image.image.attach(
          io: file_fixture(filename).open,
          filename: filename,
          content_type: content_type
        )
        product_image.save!
      end
    end

    def invalid_uploaded_file
      file = Tempfile.new([ "invalid-product-image", ".gif" ])
      file.write("not an allowed image")
      file.rewind
      @temporary_upload_files ||= []
      @temporary_upload_files << file

      Rack::Test::UploadedFile.new(file.path, "image/gif", false, original_filename: "invalid.gif")
    end
  end
end
