// ------------------ Script do html ------------ //
/** Criando a navegação entre as seções 'Chromosome input', 'SINE and LINE input'
 * e 'Results for existing job', esta etapa possibilitará os usuários a troca
 * de janelas, sem precisar sair da página pricnipal
 */

//Definindo as variáveis que receberão os elementos class
const li1 = document.getElementById('chromosome-input');
const li2 = document.getElementById('sine-line');
const li3 = document.getElementById('results-job');

const containerMain = document.querySelector('.container-main');
const containerLineSine = document.querySelector('.container-linesine');
const containerResults = document.querySelector('.container-results');

/** Definindo as funções:
 * Funcionamento: ao clicar sobre as seções, vai ativar os elementos dentro da section
 * especificada estará desativando, por meio do display: block, os elementos html
 * presente dentro das demais section
 */
li1.addEventListener('click', function() {
  if (!li1.classList.contains('li-1')) {
    li1.classList.add('li-1');
    li2.classList.remove('li-1');
    li3.classList.remove('li-1');
    containerMain.style.display = 'flex';
    containerLineSine.style.display = 'none';
    containerResults.style.display = 'none';
  }
});

li2.addEventListener('click', function() {
  if (!li2.classList.contains('li-1')) {
    li1.classList.remove('li-1');
    li2.classList.add('li-1');
    li3.classList.remove('li-1');
    containerMain.style.display = 'none';
    containerLineSine.style.display = 'flex';
    containerResults.style.display = 'none';
  }
});

li3.addEventListener('click', function() {
  if (!li3.classList.contains('li-1')) {
    li1.classList.remove('li-1');
    li2.classList.remove('li-1');
    li3.classList.add('li-1');
    containerMain.style.display = 'none';
    containerLineSine.style.display = 'none';
    containerResults.style.display = 'flex';
  }
});

// Habilitar 'container-main' por padrão
containerMain.style.display = 'flex';
containerLineSine.style.display = 'none';
containerResults.style.display = 'none';



// Função para limpar o placeholder quando o usuário começa a digitar seu email
function clearPlaceholder(input) {
	input.placeholder = '';
}

//O arquvio selecionado no input type="file" aparecerá em input type="text"
function updateFileName() {
	const fileInput = document.getElementById('inputdata');
	const fileNameInput = document.getElementById('fileNameInput');
  
	if (fileInput.files.length > 0) {
	  fileNameInput.value = fileInput.files[0].name;
	} else {
	  fileNameInput.value = '';
	}
}

//SINE E LINE
function sineUpdateFileName() {
	const sineFileInput = document.getElementById('inputdatasine');
	const sineFileNameInput = document.getElementById('fileNameInput-sine');
  
	if (sineFileInput.files.length > 0) {
	  sineFileNameInput.value = sineFileInput.files[0].name;
	} else {
	  sineFileNameInput.value = '';
	}
}

function lineUpdateFileName() {
	const lineFileInput = document.getElementById('inputdataline');
	const lineFileNameInput = document.getElementById('fileNameInput-line');
  
	if (lineFileInput.files.length > 0) {
	  lineFileNameInput.value = lineFileInput.files[0].name;
	} else {
	  lineFileNameInput.value = '';
	}
}




//habilitar checkbox
// Selecionar os elementos checkbox
const sineCheckbox = document.getElementById('sine');
const lineCheckbox = document.getElementById('line');
const completeCheckbox = document.getElementById('complete');

// Adicionar evento de clique para a checkbox 'sine', desativa o checkbox complete
completeCheckbox.addEventListener('click', function() {
  // Verifique se o checkbox 'complete' está marcado
  if (completeCheckbox.checked) {
    // Se estiver marcado, desmarque os checkboxes 'sine' e 'line'
    sineCheckbox.checked = false;
    lineCheckbox.checked = false;
  } else if (!sineCheckbox.checked && !lineCheckbox.checked) {
    // Se nenhum dos checkboxes 'sine' e 'line' estiver marcado, mantenha o checkbox 'complete' marcado
    completeCheckbox.checked = true;
  }
});

// Adicione ouvintes de evento de clique aos checkboxes 'sine' e 'line'
sineCheckbox.addEventListener('click', function() {
  // Verifique se o checkbox 'sine' está marcado
  if (sineCheckbox.checked) {
    // Se estiver marcado, desmarque o checkbox 'complete'
    completeCheckbox.checked = false;
  } else if (!lineCheckbox.checked) {
    // Se nenhum dos checkboxes 'sine' e 'line' estiver marcado, mantenha o checkbox 'sine' marcado
    sineCheckbox.checked = true;
  }
});

lineCheckbox.addEventListener('click', function() {
  // Verifique se o checkbox 'line' está marcado
  if (lineCheckbox.checked) {
    // Se estiver marcado, desmarque o checkbox 'complete'
    completeCheckbox.checked = false;
  } else if (!sineCheckbox.checked) {
    // Se nenhum dos checkboxes 'sine' e 'line' estiver marcado, mantenha o checkbox 'line' marcado
    lineCheckbox.checked = true;
  }
});


//Enquanto não houver arquivo para ser enviado, o submit fica desativado
const fileInput = document.getElementById('inputdata');
const emailInput = document.getElementById('email');
const submitButton = document.getElementById('uploaddata');

// Adicione um ouvinte de evento de entrada ao campo de email e ao campo de arquivo
emailInput.addEventListener('input', validateInputs);
fileInput.addEventListener('change', validateInputs);

// Função para verificar o formato de email válido
function isValidEmail(email) {
  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
  return emailRegex.test(email);
}

// Função para validar ambos os campos
function validateInputs() {
  const isEmailValid = isValidEmail(emailInput.value);
  const isFileSelected = fileInput.files.length > 0;

  // Habilitar ou desabilitar o botão Submit com base nas condições
  submitButton.disabled = !(isEmailValid && isFileSelected);
}

//SINE e LINE
//Selecionando os elementos inputs
const inputSine = document.getElementById('inputdatasine');
const inputLine = document.getElementById('inputdataline');
const submitButtonls = document.getElementById('uploaddatals');

//Verificando se os arquivos foram selecionados
inputSine.addEventListener('change', checkInputs);
inputLine.addEventListener('change', checkInputs);

function checkInputs() {
  // Verificar se ambos os inputs de arquivo têm arquivos selecionados
  if (inputSine.files.length > 0 && inputLine.files.length > 0) {
    // Se ambos os inputs têm arquivos selecionados, habilitar o botão de envio
    submitButtonls.disabled = false;
  } else {
    // Se algum dos inputs não tem arquivo selecionado, desabilitar o botão de envio
    submitButtonls.disabled = true;
  }
}


//Results
/** O botão load só deve ser habilitado após serem digitados os nove digitos, onde
 * os dois ultimos serão tp.
 * Porque? Esse será o formato do código de acesso ao resultado. Ele ficará salvo em um
 * BD e servirá como link temporario para acessa o site
 */
const tepFileNameInput = document.getElementById('tepFileNameInput');
const loaddataButton = document.getElementById('loaddata');

//Verificar o valor do campo de entrada
tepFileNameInput.addEventListener('input', function() {
  const value = tepFileNameInput.value.trim();
  
  // Verificar se o campo de entrada tem exatamente 24 caracteres
  if (value.length === 24) {
    //Se a condição for atendida, habilitar o botão de download
    loaddataButton.disabled = false;
  } else {
    //Caso contrário, desabilitar o botão de download
    loaddataButton.disabled = true;
  }
});





//------------------  Script para o Flask ---------------//
// var carregardados = document.getElementById("uploaddata");

// carregardados.addEventListener("click", function() {
// 	//Obtendo o arquivo de entrada
// 	var arquivoInput = document.getElementById('inputdata');
// 	var emailInput = document.getElementById('email');

// 	//Obtendo arquivo selecionado pelo usuário
// 	var arquivo = arquivoInput.files[0];
// 	var email = emailInput.value;
// 	console.log(arquivo);
// 	console.log(email);

// 	//Cria um objeto FormData e adiciona o arquivo a ele
// 	var data = new FormData();
// 	data.append('file', arquivo);
// 	data.append('email', email);

// 	//Requisitando o servidor
// 	fetch('/complete-annotation', {
// 		method: 'POST',
// 		body: data
// 	}).then(response => {
// 		//redireciona o usuário a página de sucesso
// 		console.log("Enviado");
// 	}).catch(error => {
// 		console.error(error);
// 	});


// 	const inputfile = document.getElementById('inputdata');
// 	const fileName = document.getElementById('fileNameInput');
// 	inputfile.value = '';
// 	fileName.value = '';
// 	emailInput.value = '';
// });

function getFileAndEmail() {
  //Obtendo arquivo selecionado pelo usuário
 	var arquivoInput = document.getElementById('inputdata');
 	var emailInput = document.getElementById('email');

	var arquivo = arquivoInput.files[0];
	var email = emailInput.value;

  return { arquivo, email };
}

const uploaddate = document.getElementById('uploaddata');
const sineCheck = document.getElementById('sine');
const lineCheck = document.getElementById('line');
const completeCheck = document.getElementById('complete');

// Adicionado um evento de clique ao botão 'Submit'
uploaddate.addEventListener('click', function () {
  // Verifcando o estado das checkboxes
  const isSineChecked = sineCheck.checked;
  const isLineChecked = lineCheck.checked;
  const isCompleteChecked = completeCheck.checked;

  // Lógica para determinar quais funções chamar com base nas condições
  if (isSineChecked && !isLineChecked && !isCompleteChecked) {
    execute_annotationSINE();
  } else if (!isSineChecked && isLineChecked && !isCompleteChecked) {
    execute_annotationLine();
  } else if (isSineChecked && isLineChecked && !isCompleteChecked) {
    execute_annotationSINE_LINE();
  } else if (!isSineChecked && !isLineChecked && isCompleteChecked) {
    execute_annotationCOMPLETE();
  } else {
    console.error('Condição inválida');
  }

  const inputfile = document.getElementById('inputdata');
	const fileName = document.getElementById('fileNameInput');
	inputfile.value = '';
	fileName.value = '';
	emailInput.value = '';
  sineCheckbox.checked = true;
  lineCheckbox.checked = false;
  completeCheckbox.checked = false;
  uploaddate.setAttribute("disabled", "disabled");
});

// Função para ativar apenas a anotação dos elementos SINE
function execute_annotationSINE() {
  console.log('Função execute_annotationSINE');
  const { arquivo, email } = getFileAndEmail();
  
  //Cria um objeto FormData e adiciona o arquivo a ele
 	var data = new FormData();
 	data.append('file', arquivo);
 	data.append('email', email);
  console.log(arquivo);
  console.log(email);

  //Requisitando o servidor
	fetch('/sine-annotation', {
		method: 'POST',
		body: data
	}).then(response => {
		//redireciona o usuário a página de sucesso
		console.log("Enviado");
	}).catch(error => {
		console.error(error);
	});
}

function execute_annotationLine() {
  console.log('Função execute_annotationLine');
  const { arquivo, email } = getFileAndEmail();
  
  //Cria um objeto FormData e adiciona o arquivo a ele
 	var data = new FormData();
 	data.append('file', arquivo);
 	data.append('email', email);
  console.log(arquivo);
  console.log(email);

  //Requisitando o servidor
	fetch('/line-annotation', {
		method: 'POST',
		body: data
	}).then(response => {
		//redireciona o usuário a página de sucesso
		console.log("Enviado");
	}).catch(error => {
		console.error(error);
	});

}

function execute_annotationSINE_LINE() {
  console.log('Função execute_annotationSINE_LINE');
  const { arquivo, email } = getFileAndEmail();

  //Cria um objeto FormData e adiciona o arquivo a ele
   var data = new FormData();
   data.append('file', arquivo);
   data.append('email', email);
   console.log(arquivo);
   console.log(email);

  //Requisitando o servidor
	fetch('/sineline-annotation', {
		method: 'POST',
		body: data
	}).then(response => {
		//redireciona o usuário a página de sucesso
		console.log("Enviado");
	}).catch(error => {
		console.error(error);
	});
}

function execute_annotationCOMPLETE() {
  console.log('Função execute_annotation_complete');
  const { arquivo, email } = getFileAndEmail();
  //Cria um objeto FormData e adiciona o arquivo a ele
  var data = new FormData();
  data.append('file', arquivo);
  data.append('email', email);
  console.log(arquivo);
  console.log(email);

  //Requisitando o servidor
	fetch('/complete-annotation', {
		method: 'POST',
		body: data
	}).then(response => {
		//redireciona o usuário a página de sucesso
		console.log("Enviado");
	}).catch(error => {
		console.error(error);
	});
}
