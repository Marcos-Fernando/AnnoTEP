/* //------------------  Script para o aside ---------------//
var btnExpand = document.getElementById('btn-expand');
var menuSide = document.querySelector('.aside');
var mainleft = document.querySelector('.main');

btnExpand.addEventListener('click', function(){
  menuSide.classList.toggle('expandir')
  mainleft.classList.toggle('expandir')
})

var menuItems = document.querySelectorAll('li');

menuItems.forEach(function(item) {
  item.addEventListener('click', function() {
    menuItems.forEach(function(item) {
      item.classList.remove('open');
    });

    this.classList.add('open');
  });
}); */

//------------------  Script para o aside (MOBILE) ---------------//
let menuSide = document.querySelector('.menu-side');
let menuIcon = document.querySelector('.ph-list');
let aside = document.querySelector('.aside');

menuSide.addEventListener('click', () => {
  aside.classList.toggle('showAside');
  menuIcon.classList.toggle('iconColor');
  console.log('ok!!!');
});

//----------------- Rolagem menu -----------------------//
// Captura todos os links âncora no menu
var links = document.querySelectorAll('#menu a');

// Itera pelos links e adiciona um ouvinte de evento para tratar o clique
for (var i = 0; i < links.length; i++) {
    links[i].addEventListener('click', function (event) {
        event.preventDefault(); // Impede o comportamento padrão do link
        var targetId = this.getAttribute('href').substring(1); // Obtém o ID de destino

        // Rola suavemente até o elemento de destino
        document.getElementById(targetId).scrollIntoView({ behavior: 'smooth' });
    });
}


//------------------  Script Dark Theme ---------------//
var replaceConst = document.querySelector('.replace');
var elementsWithDarkTheme = document.querySelectorAll('.non-ltr-data, .downloaddata, .container-compact, th, td, .main, .container-data,.box-explicative, .main-tr, .title-data, .footer-td, footer');
var iconHelps = document.querySelectorAll('.icon-help');
var cloudImg = document.getElementById('cloudImage');
var logoImg = document.getElementById('logoImage');

var isCloudSun = false;

replaceConst.addEventListener('click', function(){
  elementsWithDarkTheme.forEach(function(element) {
    element.classList.toggle('dark-theme');
  });

  //expressão condicional ternária ? : para alternar
  //Se isCloudSun for true, ele usará os valores no lado esquerdo do :; caso contrário, usará os valores no lado direito do :
  isCloudSun = !isCloudSun;
  cloudImg.src = isCloudSun ? 'assets/CloudSun.svg' : 'assets/CloudMoon.svg';
  logoImg.src = isCloudSun ? 'assets/Logo2.svg' : 'assets/Logo.svg';


  iconHelps.forEach(function(iconhelp) {
    iconhelp.src = isCloudSun ? 'assets/QuestionDiamond-dark.svg' : 'assets/QuestionDiamond-light.svg';
  });
});

// ==== Função para marcar a seção atual na navbar ====
const liElements = document.querySelectorAll('li');

liElements.forEach((li) => {
  li.addEventListener('click', () => {
    liElements.forEach((liOthers) => {liOthers.classList.remove('open')});
    li.classList.add('open');
  });
});

// ---- TRABALHANDO COM JSON  ---- //
function addRow(name, numElements, length, percentage) {
  var table = document.getElementById("TEs-Report-Complete");
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
function readJsonFile(file) {
  var xhr = new XMLHttpRequest();
  xhr.overrideMimeType("application/json");
  xhr.open("GET", file, true);
  xhr.onreadystatechange = function () {
      if (xhr.readyState == 4 && xhr.status == "200") {
          var jsonLines = xhr.responseText.split('\n');

          // Processar cada linha do JSON
          jsonLines.forEach(function(jsonLine) {
              // Ignorar linhas em branco
              if (jsonLine.trim() === '') {
                  return;
              }

              try {
                  var data = JSON.parse(jsonLine);
                  addRow(data.Name, data["Number of Elements"], data.Length, data.Percentage);
              } catch (e) {
                  console.error("Erro ao analisar JSON:", e);
              }
          });
      }
  };
  xhr.send(null);
}


// Ler o arquivo JSON
readJsonFile("static/TEs-Report-Complete.json");