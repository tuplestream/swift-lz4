FROM swift:5.2

WORKDIR /build
RUN git clone https://github.com/lz4/lz4.git
WORKDIR /build/lz4
RUN make
RUN make install

WORKDIR /build
