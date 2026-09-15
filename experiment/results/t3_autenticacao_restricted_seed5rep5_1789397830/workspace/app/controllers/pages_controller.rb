class PagesController < ApplicationController
  before_action :require_login, only: :protected

  def home
  end

  def protected
  end
end
