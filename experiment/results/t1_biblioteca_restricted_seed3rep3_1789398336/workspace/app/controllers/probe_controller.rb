class ProbeController < ApplicationController
  skip_forgery_protection
  def set; session[:x] = "hello"; render plain: "set"; end
  def get; render plain: "session=#{session[:x].inspect}"; end
end
