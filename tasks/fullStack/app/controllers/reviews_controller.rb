class ReviewsController < ApplicationController

  DEFAULT_TAGS = ['default']

  def index
    if params[:shop_id].present? && Shop.where("id = #{params[:shop_id]}").present?
      params[:per_page] ||= 10
      offset = params[:page].to_i * params[:per_page]

      @data = []
      products = Product.where("shop_id = #{params[:shop_id]}").sort_by(&:created_at)[offset..(offset + params[:per_page])]
      products.each do |product|
        reviews = product.reviews.sort_by(&:created_at)[offset..(offset + params[:per_page])]
        @data << { product: product, reviews: reviews }
      end
    end
  end

  def create
    # TODO: Create reviews in background. No need to show errors (if any) to users, it's fine to skip creating the review silently when some validations fail.

    tags = tags_with_default(params)

    CreateReviewWorker.perform_async({
      "product_id" => params[:review][:product_id].to_i,
      "body" => params[:review][:body],
      "rating" => params[:review][:rating].to_i,
      "reviewer_name" => params[:review][:reviewer_name],
      "tags" => tags.map(&:to_s)
    })

    flash[:notice] = 'Review is being created in background. It might take a moment to show up'
    redirect_to action: :index, shop_id: params[:shop_id]
  end

  def new
    @shops = Shop.order(:name)
    @review = Review.new
  end

  private

  # Prepend `params[:tags]` with tags of the shop (if present) or DEFAULT_TAGS
  # For simplicity, let's skip the frontend for `tags`, and just assume frontend can somehow magically send to backend `params[:tags]` as a comma-separated string
  # The logic/requirement of tags is that:
  #  - A review can have `tags` (for simplicity, tags are just an array of strings)
  #  - If the shop has some `tags`, those tags of the shop should be part of the review's `tags`
  #  - Else (if the shop doesn't have any `tags`), the default tags (in constant `DEFAULT_TAGS`) should be part of the review's `tags`
  # One may wonder what an odd logic and lenthy comment, thus may suspect something hidden here, an easter egg perhaps.
  def tags_with_default(params)
    shop = Shop.find_by(id: params[:shop_id])
    default_tags = shop.tags || DEFAULT_TAGS
    # TODO: Assuming params[:tags] is coming from the front-end, we will want to check these for security purposes (e.g. SQL injection, XSS, etc.)
    review_tags = params[:tags]&.split(',').to_a
    default_tags.concat(review_tags).uniq
  end

end
