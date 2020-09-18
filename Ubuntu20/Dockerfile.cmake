FROM gmao/ubuntu20:20.04

ARG version

RUN mkdir /src-cmake && cd /src-cmake && \
    wget https://github.com/Kitware/CMake/releases/download/v${version}/cmake-${version}.tar.gz && \
    tar xzf cmake-${version}.tar.gz && \
    cd cmake-${version} && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/cmake && \
    make -j8 && \
    make install && \
    cd / && \
    rm -rf /src-cmake

ENV PATH /cmake/bin:${PATH}

# Build command
# > docker build --build-arg version=x.y.z -f Dockerfile.cmake -t gmao/ubuntu20-cmake:<version> .
