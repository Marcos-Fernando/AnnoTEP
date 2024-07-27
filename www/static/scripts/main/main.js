// ------ Chamada do Flask ---------
function getFileAndEmail() {
  var filegenome = document.getElementById('inputdata').files[0];
  var email = document.getElementById('email').value;

  return { filegenome, email };
}

// Função para verificar o formato de email válido
function isValidEmail(email) {
  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
  return emailRegex.test(email);
  }
  
  // Função para validar ambos os campos
function validateInputs() {
  const isEmailValid = isValidEmail(emailInput.value);
  const isFileSelected = fileInput.files.length > 0;
  
  const file = fileInput.files[0];
    const maxSize = 30 * 1024 * 1024; // 30 MB
  
    // Verifica se o tamanho do arquivo é válido, se houver um arquivo selecionado
    const isFileSizeValid = file ? file.size <= maxSize : true;
  
    // Atualiza a mensagem de erro e o botão de envio
    submitButton.disabled = !(isEmailValid && isFileSelected && isFileSizeValid);
    
    // Mensagem de erro para o tamanho do arquivo
    if (!isFileSizeValid) {
      alert('The maximum size allowed is 30 MB. For annotations in larger files, we recommend downloading local versions in the Download session.');
      fileInput.value = ''; // Limpa o campo de entrada
      document.getElementById('fileNameInput').value = ''; // Limpa o nome do arquivo
    }
  }

// Função para ativar apenas a anotação dos elementos SINE
function execute_annotation(annotation_type) {
  const { filegenome, email } = getFileAndEmail();

        var data = new FormData();
        data.append('file', filegenome);
        data.append('email', email);
  data.append('annotation_type', annotation_type)

 // console.log(filegenome);
 // console.log(email);
 // console.log(annotation_type);

        fetch('/annotation-process', {
                method: 'POST',
                body: data
        }).then(response => {
                console.log("200");
        }).catch(error => {
                console.error(error);
        });

 // console.log('Dados enviado');

  const inputfile = document.getElementById('inputdata');
        const fileName = document.getElementById('fileNameInput');
        inputfile.value = '';
        fileName.value = '';
        emailInput.value = '';
}

const uploaddate = document.getElementById('uploaddata');
const sineCheck = document.getElementById('sine');
const lineCheck = document.getElementById('line');
const completeCheck = document.getElementById('complete');


// Adicionado um evento de clique ao botão 'Submit'
uploaddate.addEventListener('click', function () {
  // Verifcando o estado das checkboxes
  const isSineChecked = sineCheck.checked;
  const isLineChecked = lineCheck.checked;
  const isCompleteChecked = completeCheck.checked;

  // Lógica para determinar quais funções chamar com base nas condições
  var annotation_type;

  if (isSineChecked && !isLineChecked && !isCompleteChecked) {
    annotation_type = 1;
  } else if (!isSineChecked && isLineChecked && !isCompleteChecked) {
    annotation_type = 2;
  } else if (isSineChecked && isLineChecked && !isCompleteChecked) {
    annotation_type = 3;
  } else if (!isSineChecked && !isLineChecked && isCompleteChecked) {
    annotation_type = 4;
  } else {
    console.error('Error');
  }

  execute_annotation(annotation_type);

  sineCheck.checked = true;
  lineCheck.checked = false;
  completeCheck.checked = false;
  uploaddate.setAttribute("disabled", "disabled");

});

// --------- Envio de formulário contendo email ----------
function submitForm() {
  // Obter valores dos campos
  var userEmail = document.getElementById("help-email").value;
  var title = document.getElementById("help-title").value;
  var subject = document.getElementById("help-subject").value;

  // Criar um objeto com os dados
  var formData = {
      from: userEmail,  // Renomeie para 'from' para corresponder ao Flask
      title: title,
      subject: subject
  };

  // console.log(formData)

  // Enviar uma solicitação POST para o Flask
  fetch('/send_email', {
      method: 'POST',
      headers: {
          'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData),
  })
  .then(response => response.json())
  .then(data => {
      // Lidar com a resposta do servidor, se necessário
      console.log(data);
  })
  .catch((error) => {
      console.error('Error:', error);
  });

  clearForm();
}

function clearForm() {
  document.getElementById("help-email").value = "";
  document.getElementById("help-title").value = "";
  document.getElementById("help-subject").value = "";
}
