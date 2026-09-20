class SessionsController < ApplicationController
  # Logout may be triggered by automated clients without a CSRF token.
  skip_forgery_protection only: :destroy

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password].to_s)
      session[:user_id] = user.id
      redirect_to protected_path, notice: "Login realizado com sucesso."
    else
      @error = "Email ou senha inválidos."
      flash.now[:alert] = @error
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sessão encerrada."
  end
end
