FROM buildpack-deps:16.04-scm as os

ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -yq update
RUN apt-get -yq install -y --no-install-recommends software-properties-common 
RUN apt-get -yq upgrade 
RUN apt-get -yq install -y --no-install-recommends tree \
  nano \
  vim \
  supervisor \
  gzip \
  apt-transport-https \
  openssh-server \
  apt-utils \
  sudo \
  zip \
  libncurses5 \
  libstdc++6 \
  zlib1g \
  gedit


FROM os as rdp

RUN mkdir /var/run/sshd /usr/lib/thirdparty
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd


# Anwendungen
RUN apt-get update
RUN apt-get -yq install xfce4 xrdp xfce4-goodies lxde lxdm

RUN xrdp-keygen xrdp auto
RUN echo 'pgrep -U $(id -u) lxsession | grep -v ^$_LXSESSION_PID | xargs --no-run-if-empty kill' > /bin/lxcleanup.sh
RUN chmod +x /bin/lxcleanup.sh
RUN echo '@lxcleanup.sh' >> /etc/xdg/lxsession/LXDE/autostart

RUN apt-get clean

EXPOSE 22
EXPOSE 80
EXPOSE 3389
EXPOSE 4200
EXPOSE 1337
EXPOSE 8000
EXPOSE 27017
EXPOSE 5055

FROM rdp as vscode

RUN wget https://go.microsoft.com/fwlink/?LinkID=760868 -O code.deb \
	&& dpkg -i code.deb \
	&& rm -f code.deb
RUN apt-get install -y chromium-browser


FROM vscode as java

RUN apt-get install -y --no-install-recommends \
    openjdk-8-jdk \
	&& rm -rf /var/lib/apt/lists/*
RUN ln -svT "/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)" /usr/lib/thirdparty/docker-java-home

ENV JAVA_HOME "/usr/lib/thirdparty/docker-java-home"
RUN echo "export JAVA_HOME=/usr/lib/thirdparty/docker-java-home\n" >> /root/env
RUN echo "JAVA_HOME=/usr/lib/thirdparty/docker-java-home\n" >> /root/etc_env

FROM java as androidsdk
# Set up environment variables
ENV ANDROID_STUDIO_HOME "/usr/lib/thirdparty/android-studio"
ENV ANDROID_HOME "/usr/lib/thirdparty/android-sdk-linux"
ENV GRADLE_HOME "/usr/lib/thirdparty/android-studio/gradle"
ENV ANDROID_STUDIO_URL = "https://dl.google.com/dl/android/studio/ide-zips/3.4.1.0/android-studio-ide-183.5522156-linux.tar.gz"
RUN echo "export ANDROID_HOME=/usr/lib/thirdparty/android-sdk-linux\nexport GRADLE_HOME=/usr/lib/thirdparty/android-studio/gradle/gradle-5.1.1\n" >> /root/env
RUN echo "ANDROID_HOME=/usr/lib/thirdparty/android-sdk-linux\nGRADLE_HOME=/usr/lib/thirdparty/android-studio/gradle/gradle-5.1.1\n" >> /root/etc_env

# Download Android SDK


RUN echo "export PATH=/usr/lib/thirdparty/go/bin:/usr/lib/thirdparty/flutter/bin:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:/usr/lib/thirdparty/android-studio/gradle/gradle-5.1.1/bin:$ANDROID_HOME/platform-tools/bin:$ANDROID_HOME/build-tools/bin:${ANDROID_HOME}/platform-tools/adb:/usr/lib/thirdparty/android-studio/bin:$PATH\n" >> /root/env
RUN echo "PATH=/usr/lib/thirdparty/go/bin:/usr/lib/thirdparty/flutter/bin:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:/usr/lib/thirdparty/android-studio/gradle/gradle-5.1.1/bin:$ANDROID_HOME/platform-tools/bin:$ANDROID_HOME/build-tools/bin:${ANDROID_HOME}/platform-tools/adb:/usr/lib/thirdparty/android-studio/bin:$PATH\n" >> /root/etc_env

ENV PATH "/usr/lib/thirdparty/go/bin:/usr/lib/thirdparty/flutter/bin:${ANDROID_HOME}/tools:$ANDROID_HOME/tools/bin:/usr/lib/thirdparty/android-studio/gradle/gradle-5.1.1/bin:${ANDROID_HOME}/platform-tools/bin:${ANDROID_HOME}/build-tools/bin:${ANDROID_HOME}/platform-tools/adb:/usr/lib/thirdparty/android-studio/bin:${PATH}"
RUN cat /root/env >> /root/.bashrc
RUN cat /root/etc_env > /etc/environment
RUN apt-get -qqy update && apt-get install -y --no-install-recommends maven

# RUN mkdir "$ANDROID_HOME"
RUN curl $ANDROID_STUDIO_URL > /opt/android-studio.tar.gz
RUN tar -xvf /opt/android-studio.tar.gz -C /usr/lib/thirdparty
RUN rm /opt/android-studio.tar.gz


RUN apt-get -qqy update && apt-get -qqy install --no-install-recommends \
    qemu-kvm \
    libvirt-bin \
    ubuntu-vm-builder \
    bridge-utils \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir ~/.android ~/.gradle /dev/kvm \
&& echo "" > ~/.android/repositories.cfg

FROM androidsdk as flutter

RUN curl -O https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_v1.5.4-hotfix.2-stable.tar.xz \
	&& tar -xvf flutter_linux_v1.5.4-hotfix.2-stable.tar.xz \
	&& mv flutter /usr/lib/thirdparty \
	&& rm -f flutter_linux_v1.5.4-hotfix.2-stable.tar.xz

FROM flutter as user_setup

ARG WORKINGUSER

RUN useradd -ms /bin/bash ${WORKINGUSER}
RUN adduser ${WORKINGUSER} sudo
RUN cat /root/.bashrc > /home/${WORKINGUSER}/.bashrc


USER ${WORKINGUSER}
RUN mkdir ~/.android ~/.gradle \
&& echo "" > ~/.android/repositories.cfg

# FROM user_setup as emulator

# RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses \
# 	&& yes | sdkmanager "platform-tools" \
#   && yes | sdkmanager "tools" \
#   && yes | sdkmanager "platforms;android-28" \
#   && yes | sdkmanager "build-tools;28.0.3" \
# 	&& yes | sdkmanager "emulator" \
# 	&& yes | sdkmanager "system-images;android-28;google_apis_playstore;x86_64" \
#   && yes | sdkmanager "extras;android;m2repository" \
#   && yes | sdkmanager "extras;google;m2repository"

# RUN echo "no" | avdmanager create avd -n phone -k "system-images;android-28;google_apis_playstore;x86_64" --device "5.4in FWVGA"

FROM user_setup as fullstack

USER root
RUN mkdir /dbscripts
COPY ./files/dbscripts/* /dbscripts/
ADD ./files/supervisor.conf /etc/supervisor/conf.d/xrdp.conf
COPY ./entrypoint.sh /usr/lib/thirdparty/entrypoint.sh
RUN chmod a+x /usr/lib/thirdparty/entrypoint.sh
RUN chmod a+wrx -R /usr/lib/thirdparty
ENTRYPOINT ["/usr/lib/thirdparty/entrypoint.sh"]