class ShopsController < ApplicationController
  def products
    @products = Shop.find_by(id: params[:shop_id]).products.order(:title)
    respond_to do |format|
      format.json { render json: @products }
    end
  end
end