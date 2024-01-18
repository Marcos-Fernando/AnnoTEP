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


// ==== Função para marcar a seção atual na navbar ====
const liElements = document.querySelectorAll('li');

liElements.forEach((li) => {
  li.addEventListener('click', () => {
    liElements.forEach((liOthers) => {liOthers.classList.remove('open')});
    li.classList.add('open');
  });
});