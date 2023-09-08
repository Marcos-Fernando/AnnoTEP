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
sineCheckbox.addEventListener('click', function() {
  if (this.checked) {
    completeCheckbox.disabled = true;
    completeCheckbox.parentElement.classList.add('disabled');
  } else if (lineCheckbox.checked){
    completeCheckbox.disabled = true;
    completeCheckbox.parentElement.classList.add('disabled');
  } else {
	completeCheckbox.disabled = false;
    completeCheckbox.parentElement.classList.remove('disabled');
  }
});

// Adicionar evento de clique para a checkbox 'line', desativa o checkbox complete
lineCheckbox.addEventListener('click', function() {
  if (this.checked) {
    completeCheckbox.disabled = true;
    completeCheckbox.parentElement.classList.add('disabled');
  } else if (sineCheckbox.checked){
    completeCheckbox.disabled = true;
    completeCheckbox.parentElement.classList.add('disabled');
  } else {
    completeCheckbox.disabled = false;
    completeCheckbox.parentElement.classList.remove('disabled');
  }
});

// Adicionar evento de clique para a checkbox 'complete', desativa os checkbox line e sine
completeCheckbox.addEventListener('click', function() {
  sineCheckbox.disabled = this.checked;
  lineCheckbox.disabled = this.checked;
  sineCheckbox.parentElement.classList.toggle('disabled', this.checked);
  lineCheckbox.parentElement.classList.toggle('disabled', this.checked);
});


//Enquanto não houver arquivo para ser enviado, o submit fica desativado
//Selecionando o elemento input type="file"
const fileInput = document.getElementById('inputdata');

//Selecionar o botão de envio
const submitButton = document.getElementById('uploaddata');

//Verificando se o arquivo foi selecionado
fileInput.addEventListener('change', function() {
  if (fileInput.files.length > 0) {
    submitButton.disabled = false;
  } else {
    submitButton.disabled = true;
  }
});

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
  
  // Verificar se o campo de entrada tem exatamente 9 caracteres e os dois últimos são 'tp'
  if (value.length === 9 && value.slice(-2) === 'tp') {
    //Se a condição for atendida, habilitar o botão de download
    loaddataButton.disabled = false;
  } else {
    //Caso contrário, desabilitar o botão de download
    loaddataButton.disabled = true;
  }
});





//------------------  Script para o Flask ---------------//
var carregardados = document.getElementById("uploaddata");

carregardados.addEventListener("click", function() {
	//Obtendo o arquivo de entrada
	var arquivoInput = document.getElementById('inputdata');
	var emailInput = document.getElementById('email');

	//Obtendo arquivo selecionado pelo usuário
	var arquivo = arquivoInput.files[0];
	var email = emailInput.value;
	console.log(arquivo);
	console.log(email);

	//Cria um objeto FormData e adiciona o arquivo a ele
	var data = new FormData();
	data.append('file', arquivo);
	data.append('email', email);

	//Requisitando o servidor
	fetch('/loading', {
		method: 'POST',
		body: data
	}).then(response => {
		//redireciona o usuário a página de sucesso
		console.log("Enviado");
	}).catch(error => {
		console.error(error);
	});


	const inputfile = document.getElementById('inputdata');
	const fileName = document.getElementById('fileNameInput');
	inputfile.value = '';
	fileName.value = '';
	emailInput.value = '';
});
