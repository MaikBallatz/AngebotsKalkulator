class HomeController < ApplicationController
  def index
    # Sobald es eine eigene Startseite für Angemeldete gibt:
    # redirect_to quotes_path if user_signed_in?
  end
end
