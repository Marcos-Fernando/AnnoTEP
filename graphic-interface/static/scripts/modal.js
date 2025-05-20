//------------------  Script Modal ---------------//
var modal = document.getElementById("myModal");

// Quando o botão "Submit" for clicado, mostra o modal
uploaddate.addEventListener("click", function () {
  modal.style.display = "block";
});

// Quando o botão de fechar (x) for clicado, fecha o modal
var closeButton = document.querySelector(".close");
closeButton.addEventListener("click", function () {
  modal.style.display = "none";
});

// Fecha o modal se o usuário clicar fora dele
window.addEventListener("click", function (event) {
  if (event.target === modal) {
    modal.style.display = "none";
  }
});