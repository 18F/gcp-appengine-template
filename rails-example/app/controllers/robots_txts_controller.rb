class RobotsTxtsController < ApplicationController
  def show
    render "show", layout: false, content_type: "text/plain"
  end
end

