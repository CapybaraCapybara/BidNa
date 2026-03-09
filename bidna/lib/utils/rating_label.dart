String ratingLabel(double rating) {
  if (rating >= 5) return 'Excellent! ⭐';
  if (rating >= 4) return 'Good 👍';
  if (rating >= 3) return 'Average 😐';
  if (rating >= 2) return 'Bad 👎';
  return 'Very Bad 😞';
}