// ------ Call Flask ---------
function getFileAndEmail() {
  var filegenome = document.getElementById('inputdata').files[0];
  var email = document.getElementById('email').value;

  return { filegenome, email };
}

function getCheckedValues() {
  // Selects all the checkboxes marked in the ‘tir’ group
  const checkedTir = Array.from(document.querySelectorAll('input[name="tir"]:checked'))
    .map(checkbox => checkbox.value);
  
  // Select all the checkboxes marked in the ‘step’ group
  const checkedStep = Array.from(document.querySelectorAll('input[name="step"]:checked'))
    .map(checkbox => checkbox.value);

  return { checkedTir, checkedStep };
}

function getValuesAndValidate() {
  const mutationRateInput = document.getElementById("mutation-rate");
  const maxDivergenceInput = document.getElementById("maximun-divergence");

  const mutationRateValue = mutationRateInput.value.trim(); // Retira espaços em branco
  const maxDivergenceValue = parseFloat(maxDivergenceInput.value.trim());

  let mutationRate = "";
  let maxDivergence = "";

  // Validation for mutation rate
  const mutationRateRegex = /^[0-9]+\.[0-9]+e[-+]?[0-9]+$/; // Scientific notation
  if (mutationRateValue === "" || mutationRateValue === "1.3e-8") {
      mutationRate = "";
  } else if (!mutationRateRegex.test(mutationRateValue)) {
      alert("Please enter a valid mutation rate in scientific notation, e.g., 1.3e-8.");
      return null;
  } else {
      mutationRate = mutationRateValue;
  }

  // Validation for maximum divergence
  if (maxDivergenceValue === 40) {
      maxDivergence = "";
  } else if (maxDivergenceValue >= 0 && maxDivergenceValue <= 100) {
      maxDivergence = maxDivergenceValue.toString();
  } else {
      alert("Please enter a valid maximum divergence between 0 and 100.");
      return null;
  }

  return { mutationRate, maxDivergence };
}

function getFiles() {
  // Receive the files (if any) of the input fields
  var cdsFile = document.getElementById('cds').files[0] || null; // Returns null if there is no file
  var curateLibFile = document.getElementById('curatelib').files[0] || null;
  var maskedRegionsFile = document.getElementById('exclude').files[0] || null;
  var rmLibFile = document.getElementById('rmlib').files[0] || null;
  var rmoutFile = document.getElementById('rmout').files[0] || null;

  // Return an object with the files, which can be null or undefined if there are no files
  return {
    cdsFile,
    curateLibFile,
    maskedRegionsFile,
    rmLibFile,
    rmoutFile
  };
}


function execute_annotation(threadsValue) {
  const { filegenome, email } = getFileAndEmail();
  const { checkedTir: tircandidates, checkedStep: stepannotation } = getCheckedValues();
  const {cdsFile, curateLibFile, maskedRegionsFile, rmLibFile, rmoutFile} = getFiles();

        var data = new FormData();
        data.append('genome', filegenome);
        data.append('email', email);
        data.append('thread', threadsValue);
        
        // Adds each item from `tircandidates` and `stepannotation` individually
        tircandidates.forEach(item => data.append('tircandidates', item));
        stepannotation.forEach(item => data.append('stepannotation', item));

        const validatedValues = getValuesAndValidate();
        if (!validatedValues) return; // Terminate if validation fails
        const { mutationRate, maxDivergence } = validatedValues;

        data.append('overwrite', switchValues.overwriteValue);
        data.append('sensitivity', switchValues.sensitivityValue);
        data.append('force', switchValues.forceValue);
        data.append('tirfilter', switchValues.tirfilterValue);
        data.append('annottype', switchValues.annottypeValue);
        data.append('annotation', annotationValue);
        data.append('evaluate', evaluateValue);
        data.append("mutation_rate", mutationRate);
        data.append("max_divergence", maxDivergence);
        data.append("cds_file", cdsFile);
        data.append("curate_lib", curateLibFile);
        data.append("masked_region", maskedRegionsFile);
        data.append("rm_lib", rmLibFile);
        data.append("rmout_lib", rmoutFile);

        // console.log(filegenome);
        // console.log(email);
        // console.log(threadsValue);
        // console.log(tircandidates);
        // console.log(stepannotation);
        console.log(switchValues.tirfilterValue);
        console.log(switchValues.annottypeValue);
        // console.log(switchValues.overwriteValue);
        // console.log(switchValues.sensitivityValue);
        // console.log(annotationValue);
        // console.log(evaluateValue);
        // console.log(switchValues.forceValue);
        // console.log(mutationRate);
        // console.log(maxDivergence);
        // console.log(cdsFile);
        // console.log(curateLibFile);
        // console.log(maskedRegionsFile);
        // console.log(rmLibFile);
        // console.log(rmoutFile);

        fetch('/annotation_process', {
                method: 'POST',
                body: data
        }).then(response => {
              
              console.log("Flask response received");
        }).catch(error => {
                console.error(error);
        });

  // console.log('Dados enviado');

  setTimeout(function() {
    location.reload();
  }, 1000);

}


const uploaddate = document.getElementById('uploaddata');
const threadsInput = document.getElementById('threads'); // Make sure this ID is correct
let threadsValue;

uploaddate.addEventListener('click', function () {
  // Get the number of threads and make sure it's at least 4
  threadsValue = parseInt(threadsInput.value, 10);
  if (isNaN(threadsValue) || threadsValue < 4) {
    threadsValue = 4; // Set to 4 if empty, invalid or less than 4
    threadsInput.value = threadsValue; // Update the field to reflect the adjustment
  }

  // Executa a função com o valor corrigido
  execute_annotation(threadsValue);

});


// ------ Switch button ------- //
const switchValues = {
  overwriteValue: 0,
  sensitivityValue: 1,
  forceValue: 0,
  tirfilterValue: 0,
  annottypeValue: 0
};

let annotationValue = 0;
let evaluateValue = 0;

const switch1 = document.getElementById("switch1");
const switch2 = document.getElementById("switch2");
const switch3 = document.getElementById("switch3");
const switch4 = document.getElementById("switch4");
const switch5 = document.getElementById("switch5");
const switch6 = document.getElementById("switch6");
const switch7 = document.getElementById("switch7");

const statusTextswitch1 = document.getElementById("status-text-switch1");
const statusTextswitch2 = document.getElementById("status-text-switch2");
const statusTextswitch3 = document.getElementById("status-text-switch3");
const statusTextswitch4 = document.getElementById("status-text-switch4");
const statusTextswitch5 = document.getElementById("status-text-switch5");
const statusTextswitch6 = document.getElementById("status-text-switch6");
const statusTextswitch7 = document.getElementById("status-text-switch7");

const rmoutFileInput = document.getElementById("rmout");
const excludeFileInput = document.getElementById("exclude");
const boxrmoutInput = document.getElementById("rmoutInput");
const boxexcludeInput = document.getElementById("maskedRegionsInput");
const browseButton = document.getElementById("browseButton");  
const browseExcludeButton = document.getElementById("browseExcludeButton");  

function updateSwitchStatus(switchElement, statusTextElement, switchKey) {
  if (switchElement.checked) {
      statusTextElement.textContent = "Enabled";
      statusTextElement.style.color = "#00B37E";
      switchValues[switchKey] = 1;
  } else {
      statusTextElement.textContent = "Deactivated";
      statusTextElement.style.color = "#C4C4CC";
      switchValues[switchKey] = 0;
  }
}

switch1.addEventListener("change", function () {
  updateSwitchStatus(switch1, statusTextswitch1, 'overwriteValue');
});

switch2.addEventListener("change", function () {
  updateSwitchStatus(switch2, statusTextswitch2, 'sensitivityValue');
});

switch5.addEventListener("change", function () {
  updateSwitchStatus(switch5, statusTextswitch5, 'forceValue');
});

switch6.addEventListener("change", function () {
  updateSwitchStatus(switch6, statusTextswitch6, 'tirfilterValue');
});

switch7.addEventListener("change", function () {
  updateSwitchStatus(switch7, statusTextswitch7, 'annottypeValue');
});

// Function to update the visual and text status of switch3 (Annotation)
function updateSwitch3() {
  if (switch3.checked) {
      statusTextswitch3.textContent = "Enabled";
      statusTextswitch3.style.color = "#00B37E";
      annotationValue = 1;

      switch4.disabled = false; // Enable switch4 when switch3 is activated
      
      // Enable box-input
      rmoutFileInput.disabled = false;
      excludeFileInput.disabled = false;
      browseButton.classList.remove("disabled");
      browseExcludeButton.classList.remove("disabled");
  } else {
      statusTextswitch3.textContent = "Deactivated";
      statusTextswitch3.style.color = "#C4C4CC";
      annotationValue = 0;
      switch4.checked = false; // Deactivate switch4 if switch3 is deactivated
      switch4.disabled = true; // Disable switch4 when switch3 is disabled
      updateSwitch4(); // Updates the text and colour status of switch4

      // Desabilita a box-input
      rmoutFileInput.disabled = true;
      excludeFileInput.disabled = true;
      browseButton.classList.add("disabled");
      browseExcludeButton.classList.add("disabled");

      rmoutFileInput.value = '';
      excludeFileInput.value = '';
      boxexcludeInput.value = '';
      boxrmoutInput.value = '';
  }
}

// Function to update the visual and text status of switch4 (evaluate)
function updateSwitch4() {
  if (switch4.checked) {
      statusTextswitch4.textContent = "Enabled";
      statusTextswitch4.style.color = "#00B37E";
      evaluateValue = 1;

      switch3.checked = true; // Activates switch3 automatically if switch4 is activated
      updateSwitch3(); // Update the state of switch3 to reflect activation
  } else {
      statusTextswitch4.textContent = "Deactivated";
      statusTextswitch4.style.color = "#C4C4CC";
      evaluateValue = 0;
  }
}

// Add event listeners for the changes in switch3 and switch4
switch3.addEventListener("change", updateSwitch3);
switch4.addEventListener("change", updateSwitch4);

// Initialises the default state when loading the page
updateSwitch3();
updateSwitch4();

// =========== Finding results ============
async function atualizarStatus() {
  const res = await fetch("/status");
  const dados = await res.json();

  const ul = document.getElementById("list-results");

  // Saves the IDs of the logs that are expanded
  const logsAbertos = new Set();
  ul.querySelectorAll("li").forEach(li => {
    const name = li.dataset.name;
    const logVisivel = li.querySelector(".log-container")?.style.display === "block";
    if (logVisivel && name) logsAbertos.add(name);
  });

  ul.innerHTML = "";

  dados.forEach(item => {
    const li = document.createElement("li");
    li.dataset.name = item.name || "desconhecido";
    
    // Main div with data (name, start, end)
    const divInfo = document.createElement("div");
    let text = `<span>${item.name || "name não disponível"}</span> — `;
    
    if (item.start) {
      const inicioDate = new Date(item.start);
      const inicio = `${inicioDate.getFullYear()}/${String(inicioDate.getMonth() + 1).padStart(2, '0')}/${String(inicioDate.getDate()).padStart(2, '0')} ${String(inicioDate.getHours()).padStart(2, '0')}:${String(inicioDate.getMinutes()).padStart(2, '0')}:${String(inicioDate.getSeconds()).padStart(2, '0')}`;
      text += `<b>Starting at: </b> ${inicio} — `;
    } else {
        text += "<b>Starting at: -- </b> — ";
    }
  
    if (item.completed && item.end) {
        const fimDate = new Date(item.end * 1000);
        const fim = `${fimDate.getFullYear()}/${String(fimDate.getMonth() + 1).padStart(2, '0')}/${String(fimDate.getDate()).padStart(2, '0')} ${String(fimDate.getHours()).padStart(2, '0')}:${String(fimDate.getMinutes()).padStart(2, '0')}:${String(fimDate.getSeconds()).padStart(2, '0')}`;
        text += `<b>Ending at:</b> ${fim}`;
    } else {
        text += "<b>Ending at: -- </b> ";
    }
    
    divInfo.innerHTML = `<p>${text}</p>`;
    
    // Status div (below info, above log)
    const divStatus = document.createElement("div");
    divStatus.className = "status-container";
    
    let textStatus = "";
    let status = item.results || "Annotating ...";
    textStatus += `<b>Status:</b> ${status}`;
    
    divStatus.innerHTML = `<p>${textStatus}</p>`;
    
    // Div do log
    const divLog = document.createElement("div");
    divLog.className = "log-container";

    const logContent = item.last_lines_log?.length > 0
      ? item.last_lines_log.join("<br>")
      : "No log lines.";

    divLog.innerHTML = `<div class="log">${logContent}</div>`;
    divLog.style.display = "none";

    // Toggle button
    const toggleBtn = document.createElement("button");
    toggleBtn.classList.add("toggle-log-btn"); 
    toggleBtn.textContent = "Show log";

    toggleBtn.onclick = () => {
      const isHidden = divLog.style.display === "none";
      divLog.style.display = isHidden ? "block" : "none";
      toggleBtn.textContent = isHidden ? "Hide log" : "Show log";
    };

    // Restore expansion
    if (logsAbertos.has(item.name)) {
      divLog.style.display = "block";
      toggleBtn.textContent = "Hide log";
    }


    // Correct order of assembly
    li.appendChild(divInfo);
    li.appendChild(divStatus);
    li.appendChild(toggleBtn);
    li.appendChild(divLog);
    ul.appendChild(li);

  });
}

setInterval(atualizarStatus, 10000);
atualizarStatus();