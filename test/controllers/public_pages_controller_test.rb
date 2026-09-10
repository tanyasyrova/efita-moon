require "test_helper"

class PublicPagesControllerTest < ActionDispatch::IntegrationTest
  test "root renders home page" do
    get root_path

    assert_response :success
    assert_select "h1", "EFITA MOON"
  end

  test "about renders about page" do
    get about_path

    assert_response :success
    assert_select "h1", "EFITA MOON"
  end
end
