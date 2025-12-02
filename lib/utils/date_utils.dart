int diffMonths(DateTime start, DateTime end) {
  return (end.year - start.year) * 12 + (end.month - start.month) + 1; // inclusive month count
}
