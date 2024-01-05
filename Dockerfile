FROM ubuntu:22.04
ARG BLENDER_VERSION="4.0.2" # hardcoded if set, otherwise latest
ARG USERNAME="blenderuser"
ENV USERNAME=$USERNAME
ARG BLENDER_DEPENDENCIES="libxrender1 libx11-6 libxxf86vm1 libxfixes3 libxi6 libxfixes3 libgl1 libxkbcommon0 libsm6 libxext6 libxrender-dev"
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

COPY startup.sh /usr/local/bin/
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get upgrade && \
  apt-get install --no-install-recommends -y ca-certificates curl ocl-icd-libopencl1 tzdata xz-utils openssh-server ${BLENDER_DEPENDENCIES} && \
  ln -s libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so && \
  mkdir -p /etc/OpenCL/vendors && \
  echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd && \
  #
  echo "**** install blender ****" && \
  mkdir /blender && \
  if [ -z ${BLENDER_VERSION+x} ]; then \
    BLENDER_VERSION=$(curl -sL https://mirrors.ocf.berkeley.edu/blender/source/ \
      | awk -F'"|/"' '/blender-[0-9]*\.[0-9]*\.[0-9]*\.tar\.xz/ && !/md5sum/ {print $4}' \
      | tail -1 \
      | sed 's|blender-||' \
      | sed 's|\.tar\.xz||'); \
  fi && \
  BLENDER_FOLDER=$(echo "Blender${BLENDER_VERSION}" | sed -r 's|(Blender[0-9]*\.[0-9]*)\.[0-9]*|\1|') && \
  curl -o \
    /tmp/blender.tar.xz -L \
    "https://mirrors.ocf.berkeley.edu/blender/release/${BLENDER_FOLDER}/blender-${BLENDER_VERSION}-linux-x64.tar.xz" && \
  tar xf \
    /tmp/blender.tar.xz -C \
    /blender/ --strip-components=1 && \
  ln -s \
    /blender/blender \
    /usr/bin/blender && \
  #
  echo "**** setup user ****" && \
  useradd -m -s /bin/bash ${USERNAME} && \
  mkdir -p /home/${USERNAME}/.ssh && \
  chmod 700 /home/${USERNAME}/.ssh && \
  #
  echo "**** setup openssh ****" && \
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
  chmod +x /usr/local/bin/startup.sh && \
  service ssh start && \
  #
  echo "**** setup blender environment ****" && \
  mkdir -p /home/${USERNAME}/blender/render_submit /home/${USERNAME}/blender/blender_scripts /home/${USERNAME}/blender/render_output &&\
  #
  echo "**** cleanup ****" && \
  chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

COPY cuda_enable.py /home/$USERNAME/blender_scripts/
EXPOSE 22

RUN 
CMD [ "/usr/local/bin/startup.sh" ]
