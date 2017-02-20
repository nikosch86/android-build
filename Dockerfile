FROM ubuntu:16.04

ENV REFRESHED_AT 2017-02-20

ENV BUILD_TOOLS 23.0.3
ENV GRADLE_VERSION 2.4
ENV NODE_VERSION 6.8.1
ENV NPM_VERSION 3

ENV DEBIAN_FRONTEND noninteractive
ENV ANDROID_HOME /usr/local/android-sdk-linux
ENV ANDROID_SDK /usr/local/android-sdk-linux
ENV PATH ${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/${BUILD_TOOLS}:$PATH
ENV LD_LIBRARY_PATH ${ANDROID_SDK}/tools/lib64:${ANDROID_SDK}/tools/lib64/qt/lib:${LD_LIBRARY_PATH}
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV TERM dumb
ENV JAVA_OPTS "-Xms512m -Xmx1024m"
ENV GRADLE_OPTS "-XX:+UseG1GC -XX:MaxGCPauseMillis=1000"

RUN mkdir -p /root/.android
RUN mkdir -p /root/.gradle
COPY configs/init.gradle /root/.gradle/init.gradle

RUN set -ex \
  && apt-get update \
  && apt-get install --no-install-recommends -y apt-utils xz-utils apt-transport-https ca-certificates curl \
  build-essential lib32stdc++6 lib32z1 lib32z1-dev lib32ncurses5 libbz2-1.0 libc6-dev \
  zlib1g-dev libxml2-dev software-properties-common python-software-properties \
  unzip git wget bzip2 rsync zip curl ruby ruby-dev openssh-client default-jdk \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -ex \
    && curl -OLsS https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip

RUN gem install --no-rdoc --no-ri fastlane screengrab sigh gym

RUN set -ex \
  && curl -LsS https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz | tar xJ --strip-components 1 -C /usr \
  && if [ -x /usr/bin/npm ]; then \
    npm install -g npm@${NPM_VERSION} \
    && find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
  fi

RUN set -x \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update \
  && apt-get install -y yarn \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  && yarn -V \
  && node -v

RUN curl -L http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz | tar xz -C /usr/local/ \
  && echo y | android update sdk --no-https --no-ui --all --filter tools,platform-tools,build-tools-$BUILD_TOOLS \
  && echo y | android update sdk --no-https --no-ui --all --filter build-tools-23.0.1,build-tools-23.0.2 \
  && echo y | android update sdk --no-https --no-ui --all --filter android-23,addon-google_apis-google-23 \
  && echo y | android update sdk --no-https --no-ui --all --filter extra-android-support,extra-android-m2repository,extra-google-google_play_services,extra-google-m2repository

WORKDIR /
