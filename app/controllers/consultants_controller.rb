class ConsultantsController < ApplicationController
  def index
    @consultants = Consultant.all
  end

  def new
    @consultant = Consultant.new
  end

  def create
    @consultant = Consultant.new(consultant_params)

    if @consultant.save
      redirect_to consultants_path, notice: "Berater:in hinzugefügt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def deactivate
    consultant = Consultant.find(params[:id])
    consultant.update!(active: false)
    redirect_to consultants_path, notice: "Berater:in deaktiviert."
  end

  private

  def consultant_params
    params.require(:consultant).permit(:name, :email)
  end
end
