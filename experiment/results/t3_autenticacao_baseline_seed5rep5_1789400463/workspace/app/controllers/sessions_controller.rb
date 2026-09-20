class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password].to_s)
      reset_session
      session[:user_id] = user.id
      redirect_to protected_path, notice: "Login realizado com sucesso."
    else
      @email = params[:email]
      @error = "Email ou senha inválidos."
      flash.now[:alert] = @error
      render :new, status: :ok
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sessão encerrada."
  end
end
