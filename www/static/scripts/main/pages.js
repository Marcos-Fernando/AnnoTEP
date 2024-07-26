// ==== Código para alternar os guias da página ====
document.querySelectorAll('.home').forEach(element => {
  element.addEventListener('click', () => {
      document.querySelector('.main').style.display = 'inline-block';

      document.querySelector('.Download').style.display = 'none';
      document.querySelector('.Genome').style.display = 'none';
      document.querySelector('.Help').style.display = 'none';
      document.querySelector('.About').style.display = 'none';
      document.querySelector('.Contact').style.display = 'none';
  });
});

  
  document.getElementById('Download').addEventListener('click', () => {
    document.querySelector('.Download').style.display = 'flex';
  
    document.querySelector('.main').style.display = 'none';
    document.querySelector('.Genome').style.display = 'none';
    document.querySelector('.Help').style.display = 'none';
    document.querySelector('.About').style.display = 'none';
    document.querySelector('.Contact').style.display = 'none';
  });

  document.getElementById('Genome').addEventListener('click', () => {
    document.querySelector('.Genome').style.display = 'flex';
  
    document.querySelector('.main').style.display = 'none';
    document.querySelector('.Download').style.display = 'none';
    document.querySelector('.Help').style.display = 'none';
    document.querySelector('.About').style.display = 'none';
    document.querySelector('.Contact').style.display = 'none';
  });
  
  document.getElementById('Help').addEventListener('click', () => {
    document.querySelector('.Help').style.display = 'flex';
  
    document.querySelector('.main').style.display = 'none';
    document.querySelector('.Download').style.display = 'none';
    document.querySelector('.Genome').style.display = 'none';
    document.querySelector('.About').style.display = 'none';
    document.querySelector('.Contact').style.display = 'none';
  });
  
  document.getElementById('About').addEventListener('click', () => {
    document.querySelector('.About').style.display = 'flex';
  
    document.querySelector('.main').style.display = 'none';
    document.querySelector('.Download').style.display = 'none';
    document.querySelector('.Genome').style.display = 'none';
    document.querySelector('.Help').style.display = 'none';
    document.querySelector('.Contact').style.display = 'none';
  });
  
  document.getElementById('Contact').addEventListener('click', () => {
    document.querySelector('.Contact').style.display = 'flex';
  
    document.querySelector('.main').style.display = 'none';
    document.querySelector('.Download').style.display = 'none';
    document.querySelector('.Genome').style.display = 'none';
    document.querySelector('.Help').style.display = 'none';
    document.querySelector('.About').style.display = 'none';
  });