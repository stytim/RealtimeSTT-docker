FROM nvcr.io/nvidia/pytorch:25.06-py3 as gpu

WORKDIR /app

RUN apt-get update -y && \
  apt-get install -y portaudio19-dev libomp-dev ninja-build

# build torchaudio
ENV PYTORCH_VERSION "2.8.0a0+5228986c39.nv25.6"
ENV BUILD_VERISON "2.8.0a0+5228986"

# build custom torchaudio
WORKDIR /deps
RUN git clone https://github.com/pytorch/audio && \
    cd audio && \
    git checkout v2.8.0-rc2 && \
    python3 -m pip install -v -e . --no-use-pep517

# build custom CTranslate2 with CUDA support for ARM64
WORKDIR /deps
RUN git clone --recursive https://github.com/OpenNMT/CTranslate2.git && \
    cd CTranslate2 && \
    git checkout v4.6.0 && \
    mkdir build && \
    cd build && \
    cmake -G Ninja ../ -DWITH_CUDA=ON -DWITH_CUDNN=ON -DWITH_MKL=OFF && \
    cmake --build . --config Release && \
    cmake --install . && \
    cd ../python && \
    python3 -m pip install pybind11==2.11.1 && \
    python3 setup.py bdist_wheel && \
    python3 -m pip install dist/*.whl

WORKDIR /app

COPY requirements-gpu.txt /app/requirements-gpu.txt
RUN pip3 install -r /app/requirements-gpu.txt

COPY RealtimeSTT /app/RealtimeSTT
COPY RealtimeSTT_server /app/RealtimeSTT_server
COPY launch_two_servers.sh /app/launch_two_servers.sh

EXPOSE 9001
ENV PYTHONPATH "${PYTHONPATH}:/app"
RUN export PYTHONPATH="${PYTHONPATH}:/app"
#CMD ["python3", "RealtimeSTT_server/stt_server.py"]
CMD ["bash", "-c", "/app/launch_two_servers.sh"]

# --------------------------------------------

FROM ubuntu:22.04 as cpu

WORKDIR /app

RUN apt-get update -y && \
  apt-get install -y python3 python3-pip portaudio19-dev

RUN pip3 install torch==2.3.0 torchaudio==2.3.0

COPY requirements.txt /app/requirements.txt
RUN pip3 install -r /app/requirements.txt

EXPOSE 9001
ENV PYTHONPATH "${PYTHONPATH}:/app"
RUN export PYTHONPATH="${PYTHONPATH}:/app"
CMD ["python3", "example_browserclient/server.py"]
