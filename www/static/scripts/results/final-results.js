//------------------ Script Table ----------------------//
document.addEventListener('DOMContentLoaded', function() {
  const tableRows = document.querySelectorAll('.table-row');
  
  tableRows.forEach(function(row) {
      const nameCell = row.querySelector('td');
      const nameText = nameCell.textContent;
      if (nameText.includes('Total') || nameText.includes('Unclassified')) {
          row.classList.add('bold-row');
      }
  });
});