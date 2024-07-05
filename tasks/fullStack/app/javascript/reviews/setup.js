function setupProductSelect() {
  document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('shop_select').addEventListener('change', function() {
      const productSelect = document.getElementById('product_select');
      let loadingMessage = document.getElementById("loadingMessage");
  
      productSelect.disabled = true;
      productSelect.innerHTML = '<option value="">-- Select Product --</option>';
      loadingMessage.textContent = "Fetching products..."
      const shopId = this.value;
  
      if (shopId) {
        fetch(`/shops/${shopId}/products`)
          .then(response => response.json())
          .then(products => {
            loadingMessage.textContent = "";
            if (products.length > 0) {
              products.forEach(function(product) {
                const option = new Option(product.title, product.id);
                productSelect.appendChild(option);
              });
  
              productSelect.disabled = false;
            }
          });
      }
    });
  });
}

function setupRatingStars() {
  document.addEventListener('DOMContentLoaded', function() {
    const stars = document.querySelectorAll('#ratingContainer .star');
    const ratingInput = document.getElementById('rating');
    
    stars.forEach(star => {
      star.addEventListener('click', function() {
        const rating = this.getAttribute('data-rating');
        ratingInput.value = rating; // Update the hidden input value
        
        stars.forEach(s => {
          s.textContent = s.dataset.rating <= rating ? '★' : '☆';
        });
      });
    });
  });
}

export { setupProductSelect, setupRatingStars };
