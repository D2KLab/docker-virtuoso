FROM alpine:3.8 AS builder
LABEL maintainer="Data to Knowledge Virtual Lab <d2klab-admin@eurecom.fr>"

# Environment variables
ENV VIRTUOSO_GIT_URL=https://github.com/openlink/virtuoso-opensource.git
ENV VIRTUOSO_DIR=/virtuoso-opensource
ENV VIRTUOSO_GIT_BRANCH=develop/7
ENV VIRTUOSO_GIT_COMMIT=ffed4676dfa6df8932b6723d75043fcc8e1bbf61

COPY patch.diff /patch.diff

# Install prerequisites, download, patch, compile and install
RUN apk add --update git automake autoconf automake libtool bison flex gawk gperf openssl g++ openssl-dev make python
RUN git clone --branch ${VIRTUOSO_GIT_BRANCH} --single-branch ${VIRTUOSO_GIT_URL} ${VIRTUOSO_DIR}
WORKDIR ${VIRTUOSO_DIR}
RUN git checkout ${VIRTUOSO_GIT_COMMIT}
RUN git apply /patch.diff
RUN ./autogen.sh
RUN CFLAGS="-O2 -m64" && export CFLAGS
RUN ./configure --disable-bpel-vad --enable-conductor-vad --enable-fct-vad --disable-dbpedia-vad --disable-demo-vad --disable-isparql-vad --disable-ods-vad --disable-sparqldemo-vad --disable-syncml-vad --disable-tutorial-vad --program-transform-name="s/isql/isql-v/"
RUN make -j $(grep -c '^processor' /proc/cpuinfo)
RUN make -j $(grep -c '^processor' /proc/cpuinfo) install

# Final image
FROM alpine:3.8
ENV PATH=/usr/local/virtuoso-opensource/bin/:$PATH
RUN apk add --no-cache openssl py-pip
RUN pip install crudini
RUN mkdir -p /usr/local/virtuoso-opensource/var/lib/virtuoso/db
RUN ln -s /usr/local/virtuoso-opensource/var/lib/virtuoso/db /data

COPY --from=builder /usr/local/virtuoso-opensource /usr/local/virtuoso-opensource
COPY virtuoso.ini dump_nquads_procedure.sql enable_cors.sql clean-logs.sh virtuoso.sh /virtuoso/

WORKDIR /data
EXPOSE 8890 1111

CMD ["sh", "/virtuoso/virtuoso.sh"]
