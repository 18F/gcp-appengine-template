class WelcomeController < ApplicationController
  def index
	pp self.request.env.select {|k,v| k =~ /^HTTP_/}
  end
end
