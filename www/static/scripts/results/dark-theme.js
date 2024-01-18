//------------------  Script Dark Theme ---------------//
var replaceConst = document.querySelector('.replace');
var elementsWithDarkTheme = document.querySelectorAll('.non-ltr-data, .downloaddata, .container-compact, th, td, .main, .table-footer,.container-data,.box-explicative, .main-tr, .title-data, .footer-td, footer');
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
  cloudImg.src = isCloudSun ? '../static/assets-fixo/CloudSun.svg' : '../static/assets-fixo/CloudMoon.svg';
  logoImg.src = isCloudSun ? '../static/assets-fixo/Logo2.svg' : '../static/assets-fixo/Logo.svg';


  iconHelps.forEach(function(iconhelp) {
    iconhelp.src = isCloudSun ? '../static/assets-fixo/QuestionDiamond-dark.svg' : '../static/assets-fixo/QuestionDiamond-light.svg';
  });
});