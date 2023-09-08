// ------------------ Script do html ------------ //
//Definindo as variáveis que receberão os elementos class do report
const liReport = document.getElementById('report');
const liSimple = document.getElementById('simple-report');

const imgReport = document.querySelector('.report-complete');
const imgSimple = document.querySelector('.report-lite');

/** Definindo as funções:
 * Funcionamento: ao clicar sobre as seções, vai ativar os elementos dentro da section
 * especificada estará desativando, por meio do display: block, os elementos html
 * presente dentro das demais section
 */
liReport.addEventListener('click', function() {
  if (!liReport.classList.contains('li-1')) {
    liReport.classList.add('li-1');
    liSimple.classList.remove('li-1');
    imgReport.style.display = 'flex';
    imgSimple.style.display = 'none';
  }
});

liSimple.addEventListener('click', function() {
  if (!liSimple.classList.contains('li-1')) {
    liReport.classList.remove('li-1');
    liSimple.classList.add('li-1');
    imgReport.style.display = 'none';
    imgSimple.style.display = 'flex';
  }
});


imgReport.style.display = 'flex';
imgSimple.style.display = 'none';


//Definindo as variáveis que receberão os elementos class do ltr
const liCopia = document.getElementById('ltr-copia');
const liGypsy = document.getElementById('ltr-gypsy');

const imgCopia = document.querySelector('.copia');
const imgGypsy = document.querySelector('.gypsy');

liCopia.addEventListener('click', function() {
  if (!liCopia.classList.contains('li-2')) {
    liCopia.classList.add('li-2');
    liGypsy.classList.remove('li-2');
    imgCopia.style.display = 'flex';
    imgGypsy.style.display = 'none';
  }
});

liGypsy.addEventListener('click', function() {
  if (!liGypsy.classList.contains('li-2')) {
    liCopia.classList.remove('li-2');
    liGypsy.classList.add('li-2');
    imgCopia.style.display = 'none';
    imgGypsy.style.display = 'flex';
  }
});


imgCopia.style.display = 'flex';
imgGypsy.style.display = 'none';



//Definindo as variáveis que receberão os elementos class do phylogeny e density
const liPhy = document.getElementById('phylogeny-result');
const liDen = document.getElementById('density-result');

const imgPhy = document.querySelector('.phylogeny');
const imgDen = document.querySelector('.density');

liPhy.addEventListener('click', function() {
  if (!liPhy.classList.contains('li-3')) {
    liPhy.classList.add('li-3');
    liDen.classList.remove('li-3');
    imgPhy.style.display = 'flex';
    imgDen.style.display = 'none';
  }
});

liDen.addEventListener('click', function() {
  if (!liDen.classList.contains('li-3')) {
    liPhy.classList.remove('li-3');
    liDen.classList.add('li-3');
    imgPhy.style.display = 'none';
    imgDen.style.display = 'flex';
  }
});


imgPhy.style.display = 'flex';
imgDen.style.display = 'none';


//Sistema de zoom
const modal = document.getElementById('imageModal');
const modalImage = document.getElementById('modalImage');

// Adiciona event listener para fechar o modal ao clicar no botão de fechar (x)
document.querySelector('.close').addEventListener('click', function () {
  const modal = document.getElementById('imageModal');
  modal.style.display = 'none';
});


 // Report and Simple Report
document.querySelector('.zoom-1').addEventListener('click', function () {
  const reportComplete = document.getElementById('ml-report-complete');
  const reportLite = document.getElementById('ml-report-lite');
  
  // Define a imagem correspondente para ser mostrada no modal
  modalImage.src = reportComplete.style.display !== 'none' ? reportComplete.src : reportLite.src;

  // Mostra o modal
  modal.style.display = 'block';
});


 //Repeat Landscape Graphs
document.querySelector('.zoom-2').addEventListener('click', function () {
  const mlRepeat = document.getElementById('ml-repeat');
  
  // Define a imagem correspondente para ser mostrada no modal
  modalImage.src = mlRepeat.src;

  modal.style.display = 'block';
});


 // ltr copia and ltr gypsy
 document.querySelector('.zoom-3').addEventListener('click', function () {
  const mlCopia = document.getElementById('ml-copia');
  const mlGypsy = document.getElementById('ml-gypsy');
  
  // Define a imagem correspondente para ser mostrada no modal
  modalImage.src = mlCopia.style.display !== 'none' ? mlCopia.src : mlGypsy.src;

  // Mostra o modal
  modal.style.display = 'block';
});


 // phylogeny and density
 document.querySelector('.zoom-4').addEventListener('click', function () {
  const mlPhy = document.getElementById('ml-phy');
  const mlDen = document.getElementById('ml-den');
  
  // Define a imagem correspondente para ser mostrada no modal
  modalImage.src = mlPhy.style.display !== 'none' ? mlPhy.src : mlDen.src;

  // Mostra o modal
  modal.style.display = 'block';
});



 //Repeat pericentromeric
 document.querySelector('.zoom-5').addEventListener('click', function () {
  const mlPericentromeric = document.getElementById('ml-pericentromeric');
  
  // Define a imagem correspondente para ser mostrada no modal
  modalImage.src = mlPericentromeric.src;

  modal.style.display = 'block';
});


