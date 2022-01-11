FROM python:3.6-buster

ARG BUILDPLATFORM
ARG TARGETPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM" > /log

LABEL maintainer="micha@paw.cloud"

RUN apt-get update &&  \
    apt-get install -y apt-utils && \
    apt-get install -y openssl libffi6 libffi-dev wget cmake libyaml-dev uuid-dev && \
    wget https://github.com/libgit2/libgit2/archive/v0.25.1.tar.gz && \
	tar xzf v0.25.1.tar.gz && \
	cd libgit2-0.25.1/ && \
	cmake . -DBUILD_CLAR=OFF && \
	make && \
	make install


RUN pip install Cython==0.29.24
RUN export LIBGIT2=/usr/local && \
	export LDFLAGS="-Wl,-rpath='$LIBGIT2/lib',--enable-new-dtags $LDFLAGS" && \
    pip install git+https://github.com/libgit2/pygit2.git@4fbc1f1c059495b7331c67e12f65e57a73eb7106

COPY ./ /build
WORKDIR /build

RUN export LIBGIT2=/usr/local && \
    export LDFLAGS="-Wl,-rpath='$LIBGIT2/lib',--enable-new-dtags $LDFLAGS" && \
    pip install .
#
RUN pip install pytest
#RUN pytest .

COPY ./tests /tests
WORKDIR /tests

CMD ["pytest", "."]