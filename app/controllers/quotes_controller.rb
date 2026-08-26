class QuotesController < ApplicationController
  def index
    @quotes = Quote.all.order(created_at: :desc)
  end

  def new
    @quote = Quote.new(fee_rate_is_third: true, payment_term_days: 10, volume_limit: 150)
  end

  def show
    @quote = Quote.find(params[:id])
  end

  def create
    @quote = Quote.new(quote_params)

    if @quote.save
      redirect_to quote_path(@quote), notice: "Angebot angelegt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def quote_params
    params.require(:quote).permit(
      :angebotstyp, :consultant_id, :company_name, :contact_person, :address,
      :position, :project_reference, :minimum_fee, :fee_rate_is_third,
      :fee_rate_percentage, :payment_term_days, :volume_limit
    )
  end
end
