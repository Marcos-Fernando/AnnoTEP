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

// Função para ler e processar o arquivo JSON
function readJsonFile(file, tableId) {
  var filejson = new XMLHttpRequest();
  filejson.overrideMimeType("application/json");
  filejson.open("GET", file, true);
  filejson.onreadystatechange = function () {
      if (filejson.readyState == 4 && filejson.status == "200") {
          var jsonLines = filejson.responseText.split('\n');

          // Processar cada linha do JSON
          jsonLines.forEach(function(jsonLine) {
              // Ignorar linhas em branco
              if (jsonLine.trim() === '') {
                  return;
              }

              try {
                  var data = JSON.parse(jsonLine);
                  addRow(tableId, data.Name, data["Number of Elements"], data.Length, data.Percentage);
              } catch (e) {
                  console.error("Erro:", e);
              }
          });
      }
  };
  filejson.send(null);
}

// Ler o arquivo JSON
readJsonFile("static/TEs-Report-Complete.json", "TEs-Report-Complete");
// readJsonFile("static/TEs-Report-lite.json", "TEs-Report-lite");


document.getElementById("logoLink").onclick = function() {
    window.location.href = "/";
};