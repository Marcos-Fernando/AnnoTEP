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

document.addEventListener('DOMContentLoaded', function() {
  function setupSlides(slidesContainerSelector, slideSelector, nextButtonSelector, prevButtonSelector) {
    const slidesContainer = document.querySelector(slidesContainerSelector);
    const slides = document.querySelectorAll(slideSelector);
    const nextButton = document.getElementById(nextButtonSelector);
    const prevButton = document.getElementById(prevButtonSelector);

    let index = 0;
    const totalSlides = slides.length;

    function updateSlides() {
      const slideWidth = slides[0].offsetWidth;
      slidesContainer.style.transform = `translateX(-${index * slideWidth}px)`;
    }

    nextButton.addEventListener('click', function() {
      if (index < totalSlides - 1) {
        index++;
        updateSlides();
      } else {
        index = 0; // Voltar ao primeiro slide
        updateSlides();
      }
    });

    prevButton.addEventListener('click', function() {
      if (index > 0) {
        index--;
        updateSlides();
      } else {
        index = totalSlides - 1; // Ir ao último slide
        updateSlides();
      }
    });

    // Initialize the slides
    updateSlides();
  }

  // Setup different slide containers
  setupSlides('.slides', '.slide', 'next-slide', 'prev-slide');
  setupSlides('.slides-2', '.slide-2', 'next-slide-2', 'prev-slide-2');
  setupSlides('.slides-3', '.slide-3', 'next-slide-3', 'prev-slide-3');
});