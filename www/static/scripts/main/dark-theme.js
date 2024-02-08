//------------------  Script Dark Theme ---------------//
var replaceConst = document.querySelector('.replace');
var elementsWithDarkTheme = document.querySelectorAll('.main, .Download, .Help, .About, .Contact, .container-main, .box-checkboxs, .box-explicative, .title-input, .session-title, .header, .footer, .rectangle-green, .uploaddata, .img-dna, .img-phylogeny, .item-download, .icon-download, .container-download, .documentation-annotep, .description-about, .description-contact');
var iconHelps = document.querySelectorAll('.icon-help');
var cloudImg = document.getElementById('cloudImage');
var logoImgs = document.querySelectorAll('.logo');
var dnaImg = document.querySelector('.img-dna');
var imgFile = document.querySelector('.img-file-results');
var phylogenyImg = document.querySelector('.img-phylogeny');
var emailImg = document.querySelector('.img-email');
var shdownloads = document.querySelectorAll('.sh-download');
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
  imgFile.src = isCloudSun ? '../static/assets/file-results-dark.svg' : '../static/assets/file-results.svg';

  iconHelps.forEach(function(iconhelp) {
    iconhelp.src = isCloudSun ? '../static/assets/QuestionDiamond-dark.svg' : '../static/assets/QuestionDiamond-light.svg';
  });

  shdownloads.forEach(function(shdownload){
    shdownload.src = isCloudSun ? '../static/assets/download.svg' : '../static/assets/icon-download.svg';
  });

  logoImgs.forEach(function(logoImg){
    logoImg.src = isCloudSun ? '../static/assets/Logo2.svg' : '../static/assets/Logo.svg';
  });
});