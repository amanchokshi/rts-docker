FROM ubuntu:18.04

MAINTAINER Aman Chokshi <achokshi@student.unimelb.edu.au>

# Update and install packages
RUN apt-get -y update \
    && apt-get -y install \
    git \
    gdb \
    wget \
    cmake \
    gfortran \
    libx11-dev \
    build-essential \
    libhdf5-dev pgplot5 \
    libevent-pthreads-2.1-6 \
    wcslib-dev fftw3 fftw3-dev \
    libatlas-base-dev  libatlas-doc libatlas-test libatlas3-base \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get autoremove \
    && apt-get clean

# Enable prompt color in the skeleton .bashrc
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Install CFITSIO
RUN wget http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio_latest.tar.gz && \
    tar zxvf cfitsio_latest.tar.gz && rm -rf *tar.gz &&\
    cd cfitsio-4.0.0 && \
    ./configure --enable-reentrant --prefix=/usr/local && \
    make && make install && rm -rf ../cfitsio-4.0.0 

# Install HEALPIX (there is some backward compatability issues so build this version by hand)
RUN cd /usr/local && \
    wget http://downloads.sourceforge.net/project/healpix/Healpix_2.20a/Healpix_2.20a_2011Feb09.tar.gz && \
    tar zxvf Healpix_2.20a_2011Feb09.tar.gz && rm -rf *tar.gz &&\
    cd Healpix_2.20a/ && \

    # Open and edit top of ./configure file to #!/bin/sh to #!/bin/bash
    sed -i.bak "s|bin/sh|bin/bash|g" ./configure && \

    # Stupid interactive build process
    echo \
    '3 \ngfortran \n/ \ny \n-I$(F90_INCDIR) -DGFORTRAN -fno-second-underscore -pthread \
    \n-O3 \ngcc \n-O \nar -rsv \nlibcfitsio.a \n/usr/local/lib \
    \ny \n-L/usr/local/pgplot -lpgplot -L/usr/X11R6/lib -lX11 \n1 \ny \n0' \
    > hlpx_config && \
    ./configure -L < hlpx_config && \
    make

# Install RTS
WORKDIR /root
COPY ./mwa-RTS mwa-RTS
RUN cd mwa-RTS/utils && make && \
    cd ../src && ln -s Machines/rts-cpu-docker.mk machine.mk && \
    make rts_node_cpu

ENV LD_LIBRARY_PATH=/usr/local/lib

ENTRYPOINT /bin/bash
