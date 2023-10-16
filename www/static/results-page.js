//------------------  Script para o aside ---------------//
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
  cloudImg.src = isCloudSun ? '../static/assets/CloudSun.svg' : '../static/assets/CloudMoon.svg';
  logoImg.src = isCloudSun ? '../static/assets/Logo2.svg' : '../static/assets/Logo.svg';


  iconHelps.forEach(function(iconhelp) {
    iconhelp.src = isCloudSun ? '../static/assets/QuestionDiamond-dark.svg' : '../static/assets/QuestionDiamond-light.svg';
  });
});