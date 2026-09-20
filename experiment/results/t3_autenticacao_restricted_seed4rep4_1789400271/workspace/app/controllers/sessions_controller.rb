class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by_normalized_email(params[:email])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to protected_path
    else
      @error = "Email ou senha inválidos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path
  end
end
