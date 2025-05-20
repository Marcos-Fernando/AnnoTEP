// ==== Código para alternar os guias da página ====
function showSection(sectionToShow) {
  const sections = ['main', 'results', 'Help'];
  sections.forEach(section => {
    const element = document.querySelector(`.${section}`);
    element.style.display = section === sectionToShow ? 'flex' : 'none';
  });
}

// E então vincular os eventos:
document.getElementById('Results').addEventListener('click', () => showSection('results'));
document.getElementById('Help').addEventListener('click', () => showSection('Help'));
document.querySelectorAll('.home').forEach(el => {
  el.addEventListener('click', () => showSection('main'));
});


//=============  Aside movimentação da seleção =============//
var menuSide = document.querySelector('.aside');
var mainleft = document.querySelector('.main');
var menuItems = document.querySelectorAll('li');
var logo = document.querySelector('.logoAnnotep');

menuItems.forEach(function(item) {
  item.addEventListener('click', function() {
    menuItems.forEach(function(item) {
      item.classList.remove('open');
    });

    this.classList.add('open');
  });
});

logo.addEventListener('click', function() {
  menuItems.forEach(function(item) {
    item.classList.remove('open');
  });

  document.querySelector('li#Home').classList.add('open');
});