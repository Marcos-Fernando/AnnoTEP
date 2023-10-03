#!/bin/bash

# Lista de pacotes a serem instalados
packages=(
  absl-py
  astor
  biopython
  "blinker==1.5"
  "certifi==2021.5.30"
  "click==8.0.4"
  "dataclasses==0.8"
  dill
  "dnspython==2.2.1"
  "drmaa==0.7.9"
  "Flask==2.0.3"
  "Flask-Mail==0.9.1"
  "Flask-PyMongo==2.3.0"
  gast
  "glob2==0.4.1"
  "google-pasta==0.2.0"
  grpcio
  h5py
  importlib-metadata
  "itsdangerous==2.0.1"
  "Jinja2==3.0.3"
  joblib
  "Keras==2.3.1"
  "Keras-Applications==1.0.8"
  "Keras-Preprocessing==1.1.0"
  Mako
  Markdown
  multiprocess
  numpy
  "pandas==1.1.5"
  "Pillow==8.4.0"
  "protobuf==3.14.0"
  "pymongo==4.1.1"
  "python-dateutil==2.8.1"
  "python-dotenv==0.20.0"
  pytz
  "regex==2016.6.24"
  scikit-learn
  scipy
  six
  "tensorboard==1.14.0"
  tensorflow
  "tensorflow-estimator==1.14.0"
  "termcolor==1.1.0"
  "Theano==1.0.3"
  threadpoolctl
  "typing-extensions"
  "Werkzeug==2.0.3"
  wrapt
  zipp
)

# Loop para instalar os pacotes
for package in "${packages[@]}"; do
  pip install "$package"
done

echo "Instalação concluída!"
