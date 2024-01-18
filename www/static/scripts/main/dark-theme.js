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