#22.04 LTS
FROM ubuntu:22.04

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y curl gnupg wget python3 python3-pip python3.6 python3.10 git vim

# Copie todos os arquivos e pastas para a pasta /root/TEs/
COPY . /root/TEs/

# Porta para o MongoDB e Flask
EXPOSE 5000

# Executando o script
CMD ["/bin/bash"]


