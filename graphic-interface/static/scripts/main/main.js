// ------ Chamada do Flask ---------
function getFileAndEmail() {
  var filegenome = document.getElementById('inputdata').files[0];
  var email = document.getElementById('email').value;

  return { filegenome, email };
}

function getCheckedValues() {
  // Seleciona todos os checkboxes marcados no grupo "tir"
  const checkedTir = Array.from(document.querySelectorAll('input[name="tir"]:checked'))
    .map(checkbox => checkbox.value);
  
  // Seleciona todos os checkboxes marcados no grupo "step"
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

  // Validação para mutation rate
  const mutationRateRegex = /^[0-9]+\.[0-9]+e[-+]?[0-9]+$/; // Notação científica
  if (mutationRateValue === "" || mutationRateValue === "1.3e-8") {
      mutationRate = "";
  } else if (!mutationRateRegex.test(mutationRateValue)) {
      alert("Please enter a valid mutation rate in scientific notation, e.g., 1.3e-8.");
      return null;
  } else {
      mutationRate = mutationRateValue;
  }

  // Validação para maximum divergence
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
  // Receber os arquivos (caso existam) dos campos de input
  var cdsFile = document.getElementById('cds').files[0] || null; // Retorna null se não houver arquivo
  var curateLibFile = document.getElementById('curatelib').files[0] || null;
  var maskedRegionsFile = document.getElementById('exclude').files[0] || null;
  var rmLibFile = document.getElementById('rmlib').files[0] || null;
  var rmoutFile = document.getElementById('rmout').files[0] || null;

  // Retornar um objeto com os arquivos, podendo ser null ou undefined se não houver arquivos
  return {
    cdsFile,
    curateLibFile,
    maskedRegionsFile,
    rmLibFile,
    rmoutFile
  };
}


// Função para ativar apenas a anotação dos elementos SINE
function execute_annotation(threadsValue) {
  const { filegenome, email } = getFileAndEmail();
  const { checkedTir: tircandidates, checkedStep: stepannotation } = getCheckedValues();
  const {cdsFile, curateLibFile, maskedRegionsFile, rmLibFile, rmoutFile} = getFiles();

        var data = new FormData();
        data.append('genome', filegenome);
        data.append('email', email);
        data.append('thread', threadsValue);
        
        // Adiciona cada item de `tircandidates` e `stepannotation` individualmente
        tircandidates.forEach(item => data.append('tircandidates', item));
        stepannotation.forEach(item => data.append('stepannotation', item));

        const validatedValues = getValuesAndValidate();
        if (!validatedValues) return; // Encerra se a validação falhar
        const { mutationRate, maxDivergence } = validatedValues;

        data.append('overwrite', switchValues.overwriteValue);
        data.append('sensitivity', switchValues.sensitivityValue);
        data.append('force', switchValues.forceValue);
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
              
              console.log("Resposta do Flask recebida");
        }).catch(error => {
                console.error(error);
        });

  // console.log('Dados enviado');

  setTimeout(function() {
    location.reload();
  }, 1000);

}


const uploaddate = document.getElementById('uploaddata');
const threadsInput = document.getElementById('threads'); // Certifique-se de que este ID está correto
let threadsValue;

uploaddate.addEventListener('click', function () {
  // Obtém o valor de threads e garante que seja no mínimo 4
  threadsValue = parseInt(threadsInput.value, 10);
  if (isNaN(threadsValue) || threadsValue < 4) {
    threadsValue = 4; // Ajusta para 4 se estiver vazio, inválido ou menor que 4
    threadsInput.value = threadsValue; // Atualiza o campo para refletir o ajuste
  }

  // Executa a função com o valor corrigido
  execute_annotation(threadsValue);

  // Desabilita o botão após o clique
  // uploaddate.setAttribute("disabled", "disabled");
});


// ------ Switch button ------- //
const switchValues = {
  overwriteValue: 0,
  sensitivityValue: 1,
  forceValue: 0
};

let annotationValue = 0;
let evaluateValue = 0;

const switch1 = document.getElementById("switch1");
const switch2 = document.getElementById("switch2");
const switch3 = document.getElementById("switch3");
const switch4 = document.getElementById("switch4");
const switch5 = document.getElementById("switch5");

const statusTextswitch1 = document.getElementById("status-text-switch1");
const statusTextswitch2 = document.getElementById("status-text-switch2");
const statusTextswitch3 = document.getElementById("status-text-switch3");
const statusTextswitch4 = document.getElementById("status-text-switch4");
const statusTextswitch5 = document.getElementById("status-text-switch5");

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

// Função para atualizar o estado visual e de texto de switch3 (Annotation)
function updateSwitch3() {
  if (switch3.checked) {
      statusTextswitch3.textContent = "Enabled";
      statusTextswitch3.style.color = "#00B37E";
      annotationValue = 1;

      switch4.disabled = false; // Habilita switch4 quando switch3 está ativado
      
      // Habilita a box-input
      rmoutFileInput.disabled = false;
      excludeFileInput.disabled = false;
      browseButton.classList.remove("disabled");
      browseExcludeButton.classList.remove("disabled");
  } else {
      statusTextswitch3.textContent = "Deactivated";
      statusTextswitch3.style.color = "#C4C4CC";
      annotationValue = 0;
      switch4.checked = false; // Desativa switch4 se switch3 for desativado
      switch4.disabled = true; // Desabilita switch4 quando switch3 está desativado
      updateSwitch4(); // Atualiza o estado de texto e cor de switch4

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

// Função para atualizar o estado visual e de texto de switch4 (evaluate)
function updateSwitch4() {
  if (switch4.checked) {
      statusTextswitch4.textContent = "Enabled";
      statusTextswitch4.style.color = "#00B37E";
      evaluateValue = 1;

      switch3.checked = true; // Ativa switch3 automaticamente se switch4 for ativado
      updateSwitch3(); // Atualiza o estado de switch3 para refletir a ativação
  } else {
      statusTextswitch4.textContent = "Deactivated";
      statusTextswitch4.style.color = "#C4C4CC";
      evaluateValue = 0;
  }
}

// Adiciona ouvintes de evento para as mudanças em switch3 e switch4
switch3.addEventListener("change", updateSwitch3);
switch4.addEventListener("change", updateSwitch4);

// Inicializa o estado padrão ao carregar a página
updateSwitch3();
updateSwitch4();