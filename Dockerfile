FROM ubuntu:22.04

ARG MYSQL_ROOT_PASSWORD=nopassword

ARG REPO=mysql-5.6
ARG SRC_DIR=/app/${REPO}
ARG BUILD_DIR=${SRC_DIR}/build
ARG INSTALL_DIR=/app/myrocks
ENV BOOST_DIR=/app/boost
ENV CMAKE_DIR=/app/cmake

WORKDIR /app

RUN apt-get update && \
    apt-get install -y git gcc gfortran g++ cmake pkg-config wget

RUN apt-get install -y libbz2-dev libaio-dev bison \
    zlib1g-dev libsnappy-dev libgflags-dev libreadline6-dev libncurses5-dev \
    libssl-dev liblz4-dev libzstd-dev libudev-dev libomp-dev libopenblas-dev liblapack-dev

RUN mkdir ${BOOST_DIR} && cd ${BOOST_DIR} && \
    wget https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.bz2

RUN ARCH=$(uname -m) && \
    case ${ARCH} in \
    "x86_64") \
    CMAKE_ARCH="x86_64" ;; \
    "aarch64") \
    CMAKE_ARCH="aarch64" ;; \
    *) \
    echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac && \
    wget https://github.com/Kitware/CMake/releases/download/v3.30.3/cmake-3.30.3-linux-${CMAKE_ARCH}.tar.gz && \
    tar -xvf cmake-3.30.3-linux-${CMAKE_ARCH}.tar.gz && \
    mv /app/cmake-3.30.3-linux-${CMAKE_ARCH}/ ${CMAKE_DIR} && \
    rm cmake-3.30.3-linux-${CMAKE_ARCH}.tar.gz

RUN git clone --depth 1 https://github.com/facebook/${REPO}.git && \
    cd ${SRC_DIR} && \
    git submodule update --init --depth 1

RUN mkdir $BUILD_DIR && mkdir $INSTALL_DIR

RUN sed -i 's/libfaiss\.a/libfaiss.so/' ${SRC_DIR}/cmake/faiss.cmake && \
    sed -i 's/-DBUILD_SHARED_LIBS=OFF/-DBUILD_SHARED_LIBS=ON/' ${SRC_DIR}/cmake/faiss.cmake

WORKDIR ${BUILD_DIR}

RUN export GCC_ARCH=$(gcc -dumpmachine) && \
    export GCC_VER=$(gcc -dumpversion) && \
    ${CMAKE_DIR}/bin/cmake ${SRC_DIR} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DWITH_SSL=system \
    -DWITH_ZLIB=bundled \
    -DMYSQL_MAINTAINER_MODE=0 \
    -DENABLED_LOCAL_INFILE=1 \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=${BOOST_DIR} \
    -DWITH_FB_VECTORDB=1 \
    -DOPENMP_LIBRARY=/usr/lib/gcc/$GCC_ARCH/$GCC_VER/libgomp.so \
    -DWITH_OPENMP=/usr/lib/gcc/$GCC_ARCH/$GCC_VER/ \
    -DBLAS_LIBRARIES=/usr/lib/$GCC_ARCH/openblas-pthread/libopenblas.so \
    -DALLOW_NO_ARMV81A_CRYPTO=1 \
    -DENABLE_DTRACE=0 \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_CXX_FLAGS=" -march=native -O3 " 

RUN make -C ${BUILD_DIR} -j4

RUN make -C ${BUILD_DIR} install -j4

RUN cp ${BUILD_DIR}/faiss/faiss/libfaiss.so ${INSTALL_DIR}/lib 

ENV PATH=${INSTALL_DIR}/bin:$PATH
ENV LD_LIBRARY_PATH=${INSTALL_DIR}/lib:$LD_LIBRARY_PATH

WORKDIR ${INSTALL_DIR}

EXPOSE 3306 33060

RUN groupadd -r mysql && useradd -r -g mysql mysql
RUN mkdir ${INSTALL_DIR}/data && chown -R mysql:mysql ${INSTALL_DIR}/data

COPY --chown=mysql:mysql my.cnf /app/my.cnf

USER mysql
RUN mysqld --defaults-file=/app/my.cnf --initialize-insecure
RUN mysqld --defaults-file=/app/my.cnf --user=root --daemonize && \
    mysql -uroot -e "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" && \
    mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown

CMD ["mysqld", "--defaults-file=/app/my.cnf", "--user=mysql"]
