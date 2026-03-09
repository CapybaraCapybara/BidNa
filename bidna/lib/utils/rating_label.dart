String ratingLabel(double rating) {
  if (rating >= 5) return 'ยอดเยี่ยม! ⭐';
  if (rating >= 4) return 'ดีมาก 👍';
  if (rating >= 3) return 'พอใช้ 😐';
  if (rating >= 2) return 'ควรปรับปรุง 👎';
  return 'แย่มาก 😞';
}