class ApplicationController < ActionController::Base
  basicauth_pw = ENV.fetch('BASICAUTH_PASSWORD') {''}
  basicauth_user = ENV.fetch('BASICAUTH_USER') {'user'}
  if basicauth_pw != '' then
    logger.info "setting basic auth password"
    http_basic_authenticate_with name: basicauth_user, password: basicauth_pw
  end
end
