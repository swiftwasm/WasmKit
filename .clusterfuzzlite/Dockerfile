FROM gcr.io/oss-fuzz-base/base-builder-swift:ubuntu-24-04
RUN apt-get update && apt-get install -y make autoconf automake libtool
ENV SWIFT_PREFIX=/opt/swift
RUN mkdir -p "$SWIFT_PREFIX" && \
  curl -L https://download.swift.org/swift-6.3.2-release/ubuntu2404/swift-6.3.2-RELEASE/swift-6.3.2-RELEASE-ubuntu24.04.tar.gz | tar xz -C "$SWIFT_PREFIX" --strip-component 1
ENV PATH="$SWIFT_PREFIX/usr/bin:$PATH"
COPY . $SRC/wasmkit
WORKDIR $SRC/wasmkit
COPY .clusterfuzzlite/build.sh $SRC/
