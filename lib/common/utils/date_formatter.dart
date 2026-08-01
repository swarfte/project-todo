/// Shared date formatting used across the project, task, and step pages.
///
/// Each page used to carry its own identical `_formatDate`; this centralises it
/// so a change (e.g. localisation) lands in one place.
String formatDate(DateTime date) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
}
