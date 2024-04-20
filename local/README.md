# Using AnnoTEP Home server in terminal
### Run the Container
```sh 
docker run -it -v $HOME/results:/root/TEs/local/results -v $HOME/TEs:/{full path of the folder containing the genome} annotep-local-terminal:v1 python run_annotep.py --file {full folder path + genome name} --type 2
```

#### Exemplo:
```sh 
sudo docker run -it -v $HOME/results:/root/TEs/local/results -v $HOME/TEs:$HOME/TEs annotep-local-terminal:v1  python run_annotep.py --file $HOME/TEs/At.fasta --type 2
```

#### Description:
**Volume for Results**:
``-v $HOME/results:/root/TEs/local/results``: Creates a "volume" called ``/root/TEs/local/results`` inside the container and connects it to the ``$HOME folder /results`` on your computer. This makes it possible to share data between your computer and the container.

**Volume for Genome**:
``-v $HOME/TEs:$HOME/TEs``: Establishes a second volume called ``$HOME/TEs`` on your computer and links it to the ``$HOME/TEs`` folder on container. An inversion occurs here, as ``$HOME/TEs`` on the host (local machine) contains the genome. These volumes are used to allow the container to access and manipulate data present on the host.

**Docker Image**:
``annotep-local-terminal:v1``: Specifies the Docker image used to create the container. An image is like a "template" that contains all the elements needed for your app to work.

**Execution Command**:
``python run_annotep.py --file $HOME/TEs/At.fasta --type 2``: This is the command executed inside the container. In this case, it runs a Python script called run_annotep.py with some arguments.

``--file $HOME/TEs/At.fasta``: Indicates the complete path to the genome. This path is the same as that specified in the second volume option (``$HOME/TEs``), however, while that one indicates the location of the genome file, the ``--file`` path points directly to the genome itself.

``--type``: Refers to the type of annotation to be made:
- --type 1: SINE Annotation
- --type 2: LINE Annotation
- --type 3: SINE and LINE annotation
- --type 4: Complete Annotation