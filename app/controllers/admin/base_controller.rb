require "digest"

module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_admin!

    private

    def authenticate_admin!
      username = ENV["ADMIN_USERNAME"]
      password = ENV["ADMIN_PASSWORD"]

      return request_http_basic_authentication unless username.present? && password.present?

      authenticate_or_request_with_http_basic("EFITA MOON Admin") do |provided_username, provided_password|
        secure_compare(provided_username, username) && secure_compare(provided_password, password)
      end
    end

    def secure_compare(provided_value, expected_value)
      ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(provided_value.to_s),
        Digest::SHA256.hexdigest(expected_value.to_s)
      )
    end
  end
end
