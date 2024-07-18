// ------ Chamada do Flask ---------
function getFileAndEmail() {
  var filegenome = document.getElementById('inputdata').files[0];
  var email = document.getElementById('email').value;

  return { filegenome, email };
}

// Função para ativar apenas a anotação dos elementos SINE
function execute_annotation(annotation_type, threadsValue) {
  const { filegenome, email } = getFileAndEmail();

        var data = new FormData();
        data.append('file', filegenome);
        data.append('email', email);
        data.append('annotation_type', annotation_type);
        data.append('thread', threadsValue);

  //console.log(filegenome);
  //console.log(email);
  //console.log(annotation_type);
  console.log(threadsValue);

        fetch('/annotation-process', {
                method: 'POST',
                body: data
        }).then(response => {
                console.log("Resposta do Flask recebida");
        }).catch(error => {
                console.error(error);
        });

  console.log('Dados enviado');

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
  const threadsInput = document.getElementById('threads');

  // Lógica para determinar quais funções chamar com base nas condições
  var annotation_type;
  var threadsValue;

  if (isSineChecked && !isLineChecked && !isCompleteChecked) {
    annotation_type = 1;
  } else if (!isSineChecked && isLineChecked && !isCompleteChecked) {
    annotation_type = 2;
  } else if (isSineChecked && isLineChecked && !isCompleteChecked) {
    annotation_type = 3;
  } else if (!isSineChecked && !isLineChecked && isCompleteChecked) {
    annotation_type = 4;
  } else {
    console.error('Condição inválida');
  }

  // Adicionar evento ao campo de input de threads para garantir que o valor seja no mínimo 4
  threadsInput.addEventListener('input', function() {
    if (threadsInput.value < 4) {
      threadsValue = 4;
    }
    threadsValue = threadsInput.value;

    execute_annotation(annotation_type, threadsValue);
  });

        // Dispara um evento input artificial para garantir que execute_annotation seja chamada imediatamente
  const event = new Event('input');
  threadsInput.dispatchEvent(event);

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

  console.log(formData)

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
      console.error('Erro ao enviar dados para o Flask:', error);
  });

  clearForm();
}


function clearForm() {
  document.getElementById("help-email").value = "";
  document.getElementById("help-title").value = "";
  document.getElementById("help-subject").value = "";
}
