//------------------  Script para o aside ---------------//
//var btnExpand = document.getElementById('btn-expand');
var menuSide = document.querySelector('.aside');
var mainleft = document.querySelector('.main');

/* btnExpand.addEventListener('click', function(){
  menuSide.classList.toggle('expandir')
  mainleft.classList.toggle('expandir')
}) */

var menuItems = document.querySelectorAll('li');

menuItems.forEach(function(item) {
  item.addEventListener('click', function() {
    menuItems.forEach(function(item) {
      item.classList.remove('open');
    });

    this.classList.add('open');
  });
});

//------------------  Script para o aside (MOBILE) ---------------//
let menuMobile = document.querySelector('.menuMobile');
let menuIcon = document.querySelector('.ph-list');

menuMobile.addEventListener('click', () => {
  menuSide.classList.toggle('showAside');
  menuIcon.classList.toggle('iconColor');
  console.log('ok!!!')
});


//------------------  Script para o placeholder ---------------//
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

//------------------  Script para o checkbox ---------------//
const sineCheckbox = document.getElementById('sine');
const lineCheckbox = document.getElementById('line');
const completeCheckbox = document.getElementById('complete');

completeCheckbox.addEventListener('click', function() {
  if (completeCheckbox.checked) {
    sineCheckbox.checked = false;
    lineCheckbox.checked = false;
  } else if (!sineCheckbox.checked && !lineCheckbox.checked) {
    completeCheckbox.checked = true;
  }
});

// Adicione ouvintes de evento de clique aos checkboxes 'sine' e 'line'
sineCheckbox.addEventListener('click', function() {
  if (sineCheckbox.checked) {
    completeCheckbox.checked = false;
  } else if (!lineCheckbox.checked) {
    sineCheckbox.checked = true;
  }
});

lineCheckbox.addEventListener('click', function() {
  if (lineCheckbox.checked) {
    completeCheckbox.checked = false;
  } else if (!sineCheckbox.checked) {
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

  submitButton.disabled = !(isEmailValid && isFileSelected);
}


//------------------  Script Dark Theme ---------------//
var replaceConst = document.querySelector('.replace');
var elementsWithDarkTheme = document.querySelectorAll('.main, .container-main, .box-checkboxs, .box-explicative, .title-input, .session-title, .header, .footer, .rectangle-green, .uploaddata, .img-dna, .img-phylogeny');
var iconHelps = document.querySelectorAll('.icon-help');
var cloudImg = document.getElementById('cloudImage');
var logoImg = document.getElementById('logoImage');
var dnaImg = document.querySelector('.img-dna');
var phylogenyImg = document.querySelector('.img-phylogeny');
var emailImg = document.querySelector('.img-email');

var isCloudSun = false;

replaceConst.addEventListener('click', function(){
  elementsWithDarkTheme.forEach(function(element) {
    element.classList.toggle('dark-theme');
  });

  //expressão condicional ternária ? : para alternar
  //Se isCloudSun for true, ele usará os valores no lado esquerdo do :; caso contrário, usará os valores no lado direito do :
  isCloudSun = !isCloudSun;
  cloudImg.src = isCloudSun ? 'static/assets/CloudSun.svg' : 'static/assets/CloudMoon.svg';
  logoImg.src = isCloudSun ? 'static/assets/Logo2.svg' : 'static/assets/Logo.svg';
  dnaImg.src = isCloudSun ? 'static/assets/dna-icon-dark.svg' : 'static/assets/dna-icon.svg';
  phylogenyImg.src = isCloudSun ? 'static/assets/phylogeny-dark.svg' : 'static/assets/phylogeny.svg';
  emailImg.src = isCloudSun ? 'static/assets/email-icon-dark.svg' : 'static/assets/email-icon-light.svg';

  iconHelps.forEach(function(iconhelp) {
    iconhelp.src = isCloudSun ? 'static/assets/QuestionDiamond-dark.svg' : 'static/assets/QuestionDiamond-light.svg';
  });
});


//------------------  Script para o Flask ---------------//
function getFileAndEmail() {
  var filegenome = document.getElementById('inputdata').files[0];
  var emailInput = document.getElementById('email');

  var email = emailInput.value;

  return { filegenome, email };
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
  var annotation_type;

  if (isSineChecked && !isLineChecked && !isCompleteChecked) {
    annotation_type = 1;
  } else if (!isSineChecked && isLineChecked && !isCompleteChecked) {
    annotation_type = 2;
  } else if (isSineChecked && isLineChecked && !isCompleteChecked) {
    annotation_type = 3;
  } else if (!isSineChecked && !isLineChecked && isCompleteChecked) {
    annotation_type = 4;
  } else {
    console.error('Condição inválida');
  }

  execute_annotation(annotation_type);

  sineCheckbox.checked = true;
  lineCheckbox.checked = false;
  completeCheckbox.checked = false;
  uploaddate.setAttribute("disabled", "disabled");
 
});

// Função para ativar apenas a anotação dos elementos SINE
function execute_annotation(annotation_type) {
  const { filegenome, email } = getFileAndEmail();

 	var data = new FormData();
 	data.append('file', filegenome);
 	data.append('email', email);
  data.append('annotation_type', annotation_type)
  
  console.log(filegenome);
  console.log(email);
  console.log(annotation_type);

	fetch('/annotation-process', {
		method: 'POST',
		body: data
	}).then(response => {
		console.log("Resposta do Flask recebida");
	}).catch(error => {
		console.error(error);
	});

  console.log('Dados enviado');

  const inputfile = document.getElementById('inputdata');
	const fileName = document.getElementById('fileNameInput');
	inputfile.value = '';
	fileName.value = '';
	emailInput.value = '';
}


//------------------  Script Modal ---------------//
var modal = document.getElementById("myModal");

// Quando o botão "Submit" for clicado, mostra o modal
uploaddate.addEventListener("click", function () {
  modal.style.display = "block";
});

// Quando o botão de fechar (x) for clicado, fecha o modal
var closeButton = document.querySelector(".close");
closeButton.addEventListener("click", function () {
  modal.style.display = "none";
});

// Fecha o modal se o usuário clicar fora dele
window.addEventListener("click", function (event) {
  if (event.target === modal) {
    modal.style.display = "none";
  }
});

// ==== Código para alternar os guias da página ====
document.getElementById('Home').addEventListener('click', () => {
  document.querySelector('.main').style.display = 'inline-block';

  document.querySelector('.Download').style.display = 'none';
  document.querySelector('.Help').style.display = 'none';
  document.querySelector('.About').style.display = 'none';
  document.querySelector('.Contact').style.display = 'none';
});

document.getElementById('Download').addEventListener('click', () => {
  document.querySelector('.Download').style.display = 'flex';

  document.querySelector('.main').style.display = 'none';
  document.querySelector('.Help').style.display = 'none';
  document.querySelector('.About').style.display = 'none';
  document.querySelector('.Contact').style.display = 'none';
});

document.getElementById('Help').addEventListener('click', () => {
  document.querySelector('.Help').style.display = 'flex';

  document.querySelector('.main').style.display = 'none';
  document.querySelector('.Download').style.display = 'none';
  document.querySelector('.About').style.display = 'none';
  document.querySelector('.Contact').style.display = 'none';
});

document.getElementById('About').addEventListener('click', () => {
  document.querySelector('.About').style.display = 'flex';

  document.querySelector('.main').style.display = 'none';
  document.querySelector('.Download').style.display = 'none';
  document.querySelector('.Help').style.display = 'none';
  document.querySelector('.Contact').style.display = 'none';
});

document.getElementById('Contact').addEventListener('click', () => {
  document.querySelector('.Contact').style.display = 'flex';

  document.querySelector('.main').style.display = 'none';
  document.querySelector('.Download').style.display = 'none';
  document.querySelector('.Help').style.display = 'none';
  document.querySelector('.About').style.display = 'none';
});

// ==== Função para esconder a sidebar quando houver click fora do elemento ====