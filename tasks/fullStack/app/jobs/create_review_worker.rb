class CreateReviewWorker
  include Sidekiq::Worker

  def perform(review_params)
    Review.create!(
      product_id: review_params["product_id"],
      body: review_params["body"],
      rating: review_params["rating"],
      reviewer_name: review_params["reviewer_name"],
      tags: review_params["tags"]
    )
  end
end
