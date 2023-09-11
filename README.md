# AnnoTEP - Annotation Transposable Element for Plant
<i> Plataforma destinada a anotação de elementos transponíveis em genomas de plantas </i>

## Introdução 
AnnoTEP é uma plataforma destinada a anotação de elementos transponíveis em genomas de plantas. A plataforma tem como base o pipeline [Plant genome Annotation](https://github.com/amvarani/Plant_Annotation_TEs) e abrange diferentes características relacionadas ás classes dos TES, como: SINE, LINE, TRIM, LARD, TR_GAG, BARE-2, MITES, Gelitron, Familía Gypsy e Familia Copia.
  
O AnnoTEP encontra-se em sua fase de prototipagem e oferecerá uma versão baseado na web, contando com uma interface simples de fácil utilização, para auxiliar pesquisadores, com diferentes níveis de conhecimentos, a estarem conduzido suas anotações de forma eficiente, apresentando diferentes relatórios e gráficos como resultado. Assim como, contará com uma versão local, voltada para pesquisadores que desejam trabalhar com a plataforma em suas proprias máquinas, podendo escolher utilizar interfcae ou trabalhar com linhas de comando.

## Funções
* Identificação, validação e anotação dos elementos SINE e LINE
* Mascaramento dos genomas
* Geração de relatório sobre TEs
* Geração de gráficos ilustrando os elementos repetidos
* Geração de gráficos apresentando a idade dos elementos Gypsy e Copia
* Geração de gráfico da filogenia e densidade dos TEs

## Prerequisitos
[Python 3.7+](https://www.python.org/)
[Miniconda3](https://docs.conda.io/projects/miniconda/en/latest/)

### Criação do ambiente
Dentro da pasta www crie o ambiente de desenvolvimento:
```sh
python3 -m venv .venv
```

Agora instale o flask:
```sh
pip install flask
```

Instalando o Flask você poderá configurar variáveis de ambiente para ajudar durante a execução projeto.
Primeira instale dontenv por meio do comando:
```sh
pip install python-dotenv
```

Após esse comando você pode está criando o arquivo <b> .flaskenv </b> e configurando as váriaveis, exemplo:
```sh
FLASK_APP = "main.py"
FLASK_DEBUG = True
FLASK_ENV = development
```

A primeira,<b>FLASK_APP</b> pode ser deixada vazia e então ele procurará por "app" ou "wsgi" (com ou sem o ".py" no final, ou seja, pode ser um arquivo ou um módulo) mas você pode usar:
* Um módulo a ser importado, como FLASK_APP=hello.web;
* Um arquivo/módulo no diretório atual, por exemplo FLASK_APP=src/hello;
* Uma instância específica dentro do módulo, algo como FLASK_APP=hello:app2 ou
* Executar diretamente a factory create_app() e até com passagem de parâmetros, tipo FLASK_APP=hello:create_app('dev')".
* 
A váriavel <b>FLASK_DEBUG</b> ativá a depuração do código

E por último, a variável <b>FLASK_ENV</b> definirá o tipo de ambiente projeto, os valores reconhecidos são dois, "production" e "development", se nenhum valor for definido "production" é utilizado por padrão.

Outras informações sobre as váriaveis de desenvolvimento poderá ser encontrado no site do [Flask](https://flask.palletsprojects.com/en/2.3.x/cli/#dotenv)

Em seu bashrc adicione os comandos:
```sh
export PATH="$HOME/miniconda3/envs/AnnoSINE/bin:$PATH"
export PATH="$HOME/miniconda3/envs/EDTA/bin:$PATH"
export PATH="$HOME/TEs/non-LTR/hmmer-3.2/src/:$PATH"
```
