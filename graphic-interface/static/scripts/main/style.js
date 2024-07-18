//------------------  Placeholder ---------------//
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

const fileInput = document.getElementById('inputdata');
const emailInput = document.getElementById('email');
const submitButton = document.getElementById('uploaddata');
const sineCheckbox = document.getElementById('sine');
const lineCheckbox = document.getElementById('line');
const completeCheckbox = document.getElementById('complete');
const threadsInput = document.getElementById('threads');

// Desabilitar o campo de input de threads inicialmente
threadsInput.disabled = true;

// Enquanto não houver arquivo para ser enviado, o submit fica desativado
emailInput.addEventListener('input', validateInputs);
fileInput.addEventListener('change', validateInputs);

// Função para atualizar o estado do campo de input de threads
function updateThreadsInputState() {
  if (completeCheckbox.checked) {
  threadsInput.disabled = false;
  } else {
  threadsInput.disabled = true;
  threadsInput.value = '4'; // Limpar o valor se desabilitado
  }
}

//------------------  Script para o checkbox ---------------//
completeCheckbox.addEventListener('click', function() {
  if (completeCheckbox.checked) {
    sineCheckbox.checked = false;
    lineCheckbox.checked = false;
  } else if (!sineCheckbox.checked && !lineCheckbox.checked) {
    completeCheckbox.checked = true;
  }
  updateThreadsInputState();
});

sineCheckbox.addEventListener('click', function() {
  if (sineCheckbox.checked) {
    completeCheckbox.checked = false;
  } else if (!lineCheckbox.checked) {
    sineCheckbox.checked = true;
  }
  updateThreadsInputState();
});

lineCheckbox.addEventListener('click', function() {
  if (lineCheckbox.checked) {
    completeCheckbox.checked = false;
  } else if (!sineCheckbox.checked) {
    lineCheckbox.checked = true;
  }
  updateThreadsInputState();
});

//------------------  Aside movimentação ---------------//
var menuSide = document.querySelector('.aside');
var mainleft = document.querySelector('.main');
var menuItems = document.querySelectorAll('li');

menuItems.forEach(function(item) {
  item.addEventListener('click', function() {
    menuItems.forEach(function(item) {
      item.classList.remove('open');
    });

    this.classList.add('open');
  });
});

//------------------  Aside formato MOBILE ---------------//
let menuMobile = document.querySelector('.menuMobile');
let menuIcon = document.querySelector('.ph-list');

menuMobile.addEventListener('click', () => {
  menuSide.classList.toggle('showAside');
  menuIcon.classList.toggle('iconColor');
  console.log('ok!!!')
});

// ---------------- Sistema de envio de email Contact ------ //
function validateForm() {
  var emailInput = document.getElementById('help-email');
  var titleInput = document.getElementById('help-title');
  var subjectInput = document.getElementById('help-subject');
  var submitContact = document.getElementById('uploadcontact');

  if (emailInput.value.trim() !== '' && titleInput.value.trim() !== '' && subjectInput.value.trim() !== '') {
    submitContact.disabled = false;
  } else {
    submitContact.disabled = true;
  }
}
