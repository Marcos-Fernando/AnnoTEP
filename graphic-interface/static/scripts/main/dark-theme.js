//------------------  Script Dark Theme ---------------//
var replaceConst = document.querySelector('.replace');
var elementsWithDarkTheme = document.querySelectorAll('.main, .Download, .Help, .container-main, .box-checkboxs, .container-threads, .box-explicative, .title-input, .session-title, .header, .footer, .rectangle-green, .uploaddata, .img-dna, .img-phylogeny, .item-download, .icon-download, .container-download, .documentation-annotep, .description-about, .description-contact');
var cloudImg = document.getElementById('cloudImage');
// var logoImg = document.getElementById('logoImage');
var logoImgs = document.querySelectorAll('.logo'); // Seleciona todas as imagens com a classe 'logoImage'

var dnaImg = document.querySelector('.img-dna');
var phylogenyImg = document.querySelector('.img-phylogeny');
var emailImg = document.querySelector('.img-email');
var mains = document.querySelectorAll('main');

var isCloudSun = false;

replaceConst.addEventListener('click', function(){
  elementsWithDarkTheme.forEach(function(element) {
    element.classList.toggle('dark-theme');
  });

  //expressão condicional ternária ? : para alternar
  //Se isCloudSun for true, ele usará os valores no lado esquerdo do :; caso contrário, usará os valores no lado direito do :
  isCloudSun = !isCloudSun;
  cloudImg.src = isCloudSun ? '../static/assets/CloudSun.svg' : '../static/assets/CloudMoon.svg';
  dnaImg.src = isCloudSun ? '../static/assets/dna-icon-dark.svg' : '../static/assets/dna-icon.svg';
  phylogenyImg.src = isCloudSun ? '../static/assets/phylogeny-dark.svg' : '../static/assets/phylogeny.svg';
  emailImg.src = isCloudSun ? '../static/assets/email-icon-dark.svg' : '../static/assets/email-icon-light.svg';
  // logoImg.src = isCloudSun ? '../static/assets/Logo2.svg' : '../static/assets/Logo.svg';

  logoImgs.forEach(function(logoImg) {
    logoImg.src = isCloudSun ? '../static/assets/Logo2.svg' : '../static/assets/Logo.svg';
  });
});