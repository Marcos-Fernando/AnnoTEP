// ---- TRABALHANDO COM JSON  ---- //
function addRow(tableId, name, numElements, length, percentage) {
  var table = document.getElementById(tableId);
  var row = table.insertRow(-1);

  var cell1 = row.insertCell(0);
  var cell2 = row.insertCell(1);
  var cell3 = row.insertCell(2);
  var cell4 = row.insertCell(3);

  cell1.innerHTML = name;
  cell2.innerHTML = numElements;
  cell3.innerHTML = length;
  cell4.innerHTML = percentage;
}

//Voltar paa tela inicial
document.getElementById("logoLink").onclick = function() {
    window.location.href = "/";
};

// Função para ler e processar o arquivo JSON
// function readJsonFile(file, tableId) {
//   var filejson = new XMLHttpRequest();
//   filejson.overrideMimeType("application/json");
//   filejson.open("GET", file, true);
//   filejson.onreadystatechange = function () {
//       if (filejson.readyState == 4 && filejson.status == "200") {
//           var jsonLines = filejson.responseText.split('\n');

//           // Processar cada linha do JSON
//           jsonLines.forEach(function(jsonLine) {
//               // Ignorar linhas em branco
//               if (jsonLine.trim() === '') {
//                   return;
//               }

//               try {
//                   var data = JSON.parse(jsonLine);
//                   addRow(tableId, data.Name, data["Number of Elements"], data.Length, data.Percentage);
//               } catch (e) {
//                   console.error("Erro:", e);
//               }
//           });
//       }
//   };
//   filejson.send(null);
// }

// // Ler o arquivo JSON
// readJsonFile("static/TEs-Report-Complete.json", "TEs-Report-Complete");
// // readJsonFile("static/TEs-Report-lite.json", "TEs-Report-lite");


//colocando a tabela direto da imagem
document.addEventListener('DOMContentLoaded', function() {
    fetch('../static/screenshot/TEs-Report-Complete.txt')
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.text();
        })
        .then(text => {
            displayContent(text);
        })
        .catch(error => {
            console.error('There has been a problem with your fetch operation:', error);
        });
});

function displayContent(text) {
    const output = document.getElementById('output');
    output.textContent = text;
}

// ALterar a tabela do report
// document.addEventListener('DOMContentLoaded', function() {
//     function applyIndentation() {
//         const rows = document.querySelectorAll('#TEs-Report-Complete tr');

//         rows.forEach(row => {
//             const firstCell = row.querySelector('td');

//             if (firstCell) {
//                 const textContent = firstCell.textContent.trim();
//                 let symbol = '';

//                 // Define o símbolo com base no conteúdo da célula
//                 if (textContent.includes('Class I Total')) {
//                     symbol = '';
//                 } else if (textContent.includes('Non-LTR')) {
//                     symbol = '>';
//                 } else if (textContent.includes('SINEs')) {
//                     symbol = '> > ';
//                 } else if (textContent.includes('LINEs')) {
//                     symbol = '> > ';
//                 } else if (textContent.includes('LINE-like')) {
//                     symbol = '> > > ';
//                 }

//                 // Adiciona o símbolo no início da célula
//                 if (symbol) {
//                     firstCell.innerHTML = `<span class="indent-symbol">${symbol}</span><span>|--</span>${firstCell.innerHTML}`;
//                 }
//             }
//         });
//     }

//     // Chama a função após a tabela ser preenchida com dados
//     setTimeout(applyIndentation, 1000); // Ajuste o tempo conforme necessário
// });





