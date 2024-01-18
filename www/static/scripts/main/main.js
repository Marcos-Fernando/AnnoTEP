// ------ Chamada do Flask ---------
function getFileAndEmail() {
  var filegenome = document.getElementById('inputdata').files[0];
  var email = document.getElementById('email').value;

  return { filegenome, email };
}

// Função para ativar apenas a anotação dos elementos SINE
function execute_annotation(annotation_type) {
  const { filegenome, email } = getFileAndEmail();

 	var data = new FormData();
 	data.append('file', filegenome);
 	data.append('email', email);
  data.append('annotation_type', annotation_type)
  
  console.log(filegenome);
  console.log(email);
  console.log(annotation_type);

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
    console.error('Condição inválida');
  }

  execute_annotation(annotation_type);

  sineCheck.checked = true;
  lineCheck.checked = false;
  completeCheck.checked = false;
  uploaddate.setAttribute("disabled", "disabled");
 
});

