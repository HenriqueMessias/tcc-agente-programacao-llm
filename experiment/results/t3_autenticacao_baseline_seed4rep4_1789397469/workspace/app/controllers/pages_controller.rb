class PagesController < ApplicationController
  before_action :require_login

  def protected
  end
end
