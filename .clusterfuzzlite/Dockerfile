FROM gcr.io/oss-fuzz-base/base-builder-swift
RUN apt-get update && apt-get install -y make autoconf automake libtool
COPY . $SRC/wasmkit
WORKDIR $SRC/wasmkit
COPY .clusterfuzzlite/build.sh $SRC/
