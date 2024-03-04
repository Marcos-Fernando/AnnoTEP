# AnnoTEP Local terminal
## _Guide to installing and using Annotep Local version terminal (via Docker)_
To facilitate the user experience on different Linux distributions, we avoided the need to install several libraries locally. We have chosen to create a Docker image that includes the annotation system present on the AnnoTEP platform.

In this approach, the environment has no interface and is run directly via the command line in the terminal. In addition, unlike its version with an interface, the image does not require the internet to perform the annotation, as its process will take place all over the world. 

## Prerequisites:
- Make sure you have Docker installed on your machine. You can download and install Docker from the [official Docker website](https://docs.docker.com/desktop/install/linux-install/).

## Installation:
### Step 1: Download the Docker Image
Run the following command to download the Docker Hub image:
```sh
   docker pull marcosnando/annotep-local-terminal:v1
```

### Step 2: Run the Container
Now run the container using the following command:

```sh 
docker run -it -v $HOME/results:/root/TEs/local/results -v $HOME/TEs:/{full path of the folder containing the genome} marcosnando/annotep-local-terminal:v1 python run_annotep.py --file {full folder path + genome name} --type 2
```

#### Exemplo:
```sh 
sudo docker run -it -v $HOME/results:/root/TEs/local/results -v $HOME/TEs:/home/user/TEs marcosnando/annotep-local-terminal:v1  python run_annotep.py --file /home/user/TEs/At.fasta --type 2
```

#### Description:
**Volume for Results**:
``-v $HOME/results:/root/TEs/local/results``: Creates a "volume" called ``/root/TEs/local/results`` inside the container and connects it to the ``$HOME folder /results`` on your computer. This makes it possible to share data between your computer and the container.

**Volume for Genome**:
``-v $HOME/TEs:/home/user/TEs``: Establishes a second volume called ``/home/user/TEs`` on your computer and links it to the ``$HOME/TEs`` folder on container. An inversion occurs here, as ``/home/user/TEs`` on the host (local machine) contains the genome. These volumes are used to allow the container to access and manipulate data present on the host.

**Docker Image**:
``marcosnando/annotep-local-terminal:v1``: Specifies the Docker image used to create the container. An image is like a "template" that contains all the elements needed for your app to work.

**Execution Command**:
``python run_annotep.py --file /home/user/TEs/At.fasta --type 2``: This is the command executed inside the container. In this case, it runs a Python script called run_annotep.py with some arguments.

``--file /home/user/TEs/At.fasta``: Indicates the complete path to the genome. This path is the same as that specified in the second volume option (``/home/user/TEs``), however, while that one indicates the location of the genome file, the ``--file`` path points directly to the genome itself.

``--type``: Refers to the type of annotation to be made:
- --type 1: SINE Annotation
- --type 2: LINE Annotation
- --type 3: SINE and LINE annotation
- --type 4: Complete Annotation