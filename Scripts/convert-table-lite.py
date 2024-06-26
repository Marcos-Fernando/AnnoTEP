import re
import csv

# Ler o conteúdo do arquivo report.txt
with open('TEs-Report-lite.txt', 'r') as file:
    content = file.read()

# Remover as aspas, espaços em branco e linhas em branco
cleaned_content = re.sub(r'["\n]', '', content)

# Remover a linha "Results---------------------------"
cleaned_content = re.sub(r'Results-+', '', cleaned_content)

# Substituir "-----------------------------------------------------------------------Unclassified" por "Unclassified"
cleaned_content = re.sub(r'-+Unclassified', 'Unclassified', cleaned_content)

# Inicializar uma lista para armazenar os dados
data = []

# Usar expressões regulares para extrair os nomes e números
pattern = r'\|?([\w\s-]+):\s+(\d+)\s+(\d+)\s+bp\s+(\d+\.\d+ \%)'
matches = re.findall(pattern, cleaned_content)

# Iterar pelas correspondências e armazenar na lista de dados
for match in matches:
    name, num_elements, length, percentage = match
    if name.startswith('-'):
        name = name[1:]  # Remove o primeiro caractere "-"
    percentage = percentage.replace('%', '').strip()
    data.append([name, num_elements, length, percentage])

# Agora, você pode salvar os dados em um arquivo CSV
csv_file = 'TEs-Report-lite.csv'
with open(csv_file, 'w', newline='') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(['Name', 'Number of Elements', 'Length', 'Percentage (%)'])  # Escreve o cabeçalho
    for row in data:
        csv_writer.writerow(row)

print(f'Data successfully saved in {csv_file}.')

