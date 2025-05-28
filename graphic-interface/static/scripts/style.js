//------------------  Placeholder ---------------//
function clearPlaceholder(input) {
  input.placeholder = '';
}

//O arquvio selecionado no input type="file" aparecerá em input type="text"
function updateFileName(inputFileId, inputTextId) {
  const fileInput = document.getElementById(inputFileId);
  const textInput = document.getElementById(inputTextId);

  if (fileInput.files.length > 0) {
    textInput.value = fileInput.files[0].name;
  } else {
    textInput.value = '';
  }
}

// Adicionar os eventos onchange para cada campo
document.getElementById('inputdata').addEventListener('change', () => updateFileName('inputdata', 'fileNameInput'));
document.getElementById('cds').addEventListener('change', () => updateFileName('cds', 'cdsInput'));
document.getElementById('curatelib').addEventListener('change', () => updateFileName('curatelib', 'curateLibInput'));
document.getElementById('exclude').addEventListener('change', () => updateFileName('exclude', 'maskedRegionsInput'));
document.getElementById('rmlib').addEventListener('change', () => updateFileName('rmlib', 'rmLibInput'));
document.getElementById('rmout').addEventListener('change', () => updateFileName('rmout', 'rmoutInput'));



// Função para verificar o formato de email válido
// function isValidEmail(email) {
//   const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
//   return emailRegex.test(email);
// }

// Função para validar ambos os campos
function validateInputs() {
  const isFileSelected = fileInput.files.length > 0;

  submitButton.disabled = !(isFileSelected);
}

const fileInput = document.getElementById('inputdata');
const submitButton = document.getElementById('uploaddata');


fileInput.addEventListener('change', validateInputs);


// ----- checkbox --- //
function toggleCheckbox(groupClass, clickedCheckbox) {
  // Seleciona todos os checkboxes no grupo
  const checkboxes = document.querySelectorAll(`.${groupClass} .checkbox-tir, .${groupClass} .checkbox-step`);
  
  // Desmarca todos os checkboxes do grupo
  checkboxes.forEach(checkbox => {
      if (checkbox !== clickedCheckbox) {
          checkbox.checked = false;
      }
  });

  // Ativa o checkbox clicado
  clickedCheckbox.checked = true;
}


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
let menuIcon = document.querySelector('.menuIcon');

menuMobile.addEventListener('click', () => {
  menuSide.classList.toggle('showAside');
  menuIcon.classList.toggle('iconColor');
});

let menuOpen = false;

menuMobile.addEventListener('click', () => {
  menuOpen = !menuOpen;
  setTimeout(() => {
    menuIcon.src = menuOpen
      ? "../static/assets/icon_close.png"
      : "../static/assets/icon_menu.png";
  }, 250);
});
