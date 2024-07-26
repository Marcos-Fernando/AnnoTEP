//------------------  Script Dark Theme ---------------//
var replaceConst = document.querySelector('.replace');
var elementsWithDarkTheme = document.querySelectorAll('.non-ltr-data, .downloaddata, .container-compact, th, td, .main, .table-footer,.container-data,.box-explicative, .main-tr, .title-data, .footer-td, footer, .note, .intro-result');
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