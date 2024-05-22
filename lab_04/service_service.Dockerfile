FROM ubuntu
ENV TZ=Europe/Moscow
RUN apt-get update && apt-get install -y git python3 pip iputils-ping cmake gcc-12 libpq-dev postgresql-client wrk libssl-dev zlib1g-dev librdkafka-dev mysql-client libmysqlclient-dev libboost-all-dev\
    && apt-get clean

RUN git clone -b poco-1.13.2-release https://github.com/pocoproject/poco.git &&\
    cd poco &&\
    mkdir cmake-build &&\
    cd cmake-build &&\
    cmake .. &&\
    cmake --build . --config Release &&\
    cmake --build . --target install &&\
    cd && rm poco/* -rf


RUN ldconfig
COPY ./ /service_service/
WORKDIR /service_service
RUN pip install -r ./requirements.txt --break-system-packages
RUN cmake -B build -S service_service && cmake --build build
ENTRYPOINT [ "bash", "./service_service/start.sh" ]
