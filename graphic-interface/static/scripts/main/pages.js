// ==== Código para alternar os guias da página ====
document.querySelectorAll('.home').forEach(element => {
  element.addEventListener('click', () => {
      document.querySelector('.main').style.display = 'inline-block';
      document.querySelector('.Help').style.display = 'none';
  });
});
  
document.getElementById('Help').addEventListener('click', () => {
  document.querySelector('.Help').style.display = 'flex';
  document.querySelector('.main').style.display = 'none';
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