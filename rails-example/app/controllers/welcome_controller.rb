class WelcomeController < ApplicationController
  def index
	if ENV["RAILS_LOG_HEADERS"].present?
		logger.info self.request.env.select {|k,v| k =~ /^HTTP_/}
	end
  end
end
