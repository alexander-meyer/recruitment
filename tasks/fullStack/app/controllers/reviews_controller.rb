class ReviewsController < ApplicationController

  DEFAULT_TAGS = ['default']

  def index
    params[:per_page] ||= 10
    offset = params[:page].to_i * params[:per_page]

    products_query = Product.includes(:reviews).order(created_at: :desc)
    products_query = products_query.where(shop_id: params[:shop_id].to_i) if params[:shop_id].present?

    products = products_query.limit(params[:per_page].to_i).offset(offset)
    product_ids = products.pluck(:id)

    reviews = Review.where(product_id: product_ids).group_by(&:product_id)

    @data = products.map do |product|
      {
        product: product,
        reviews: reviews[product.id].try(:sort_by, &:created_at).try(:first, 3) || []
      }
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
    default_tags = shop&.tags || DEFAULT_TAGS
  
    review_tags = sanitize_tags(params[:tags])
    
    (default_tags + review_tags).uniq
  end

  def sanitize_tags(tags_string)
    return [] unless tags_string
    tags_string.split(',').map { |tag| tag.strip.gsub(/[^0-9a-zA-Z \-_]+/, '') }
  end

end
