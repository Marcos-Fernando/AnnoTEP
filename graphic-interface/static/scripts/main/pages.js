// ==== Código para alternar os guias da página ====
document.getElementById('Home').addEventListener('click', () => {
  document.querySelector('.main').style.display = 'inline-block';
  document.querySelector('.Help').style.display = 'none';
});
  
document.getElementById('Help').addEventListener('click', () => {
  document.querySelector('.Help').style.display = 'flex';
  document.querySelector('.main').style.display = 'none';
});
  // ==== Função para esconder a sidebar quando houver click fora do elemento ====