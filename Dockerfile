FROM beevelop/android:latest as android-nodejs

RUN apt-get update && \
    apt-get -y install openjdk-11-jdk-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    java -version

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

RUN apt-get update && apt-get install -y curl gnupg2 lsb-release

RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs

RUN apt-get install -y nodejs && \
    node -v && npm -v

RUN npm install -g yarn && \
    yarn -v

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM android-nodejs

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    vim \
    jq \ 
    curl

ENV TZ="America/Fortaleza"
ENV ROOT="/root/"
ENV APP_NAME="app"
ENV ROOT_APP_NAME="${ROOT}${APP_NAME}/"
ENV WEBPACK_BUILD_COMMAND="build:cordova"
ENV BUILD_FOLDER="www"
ENV ANDROID_HOME=${ANDROID_SDK_ROOT}

VOLUME ${ROOT}apk/

WORKDIR ${ROOT}

RUN npm install -g npm@latest
RUN npm install -g cordova@latest
RUN node -v && npm -v && cordova -v
RUN apt-get update && apt-get install build-essential -y --no-install-recommends

RUN cordova telemetry on \
	&& cordova create ${APP_NAME}

WORKDIR ${ROOT_APP_NAME}

RUN cordova platform add android@latest \
 && cordova plugin add cordova-plugin-geolocation \
 && cordova plugin add cordova-plugin-camera \
 && cordova plugin add cordova-android-support-gradle-release

RUN cordova build android

RUN rm -rf www/

WORKDIR ${ROOT}

COPY sh/nodejs/package.* nodejs/
RUN cd nodejs/ && npm install && cd ..

COPY sh/ /usr/local/bin/
COPY sh/nodejs/*.js nodejs/

RUN chmod +x /usr/local/bin/prepare.sh \
 && chmod +x /usr/local/bin/build.sh \
 && chmod +x /usr/local/bin/bundle.sh \
 && chmod +x /usr/local/bin/fbuild.sh \
 && chmod +x /usr/local/bin/release.sh \
 && chmod +x /usr/local/bin/frelease.sh \
 && chmod +x /usr/local/bin/entrypoint.sh \
 && chmod +x /usr/local/bin/change-version.sh \
 && chmod +x /usr/local/bin/compile-webpack.sh

RUN rm -rf /var/lib/apt/lists/*

WORKDIR ${ROOT_APP_NAME}

ENTRYPOINT [ "entrypoint.sh" ]