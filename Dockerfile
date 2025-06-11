FROM selidocker.seli.gic.ericsson.se/proj-lantern/base/angular-service:0.0.9 as build

WORKDIR /lantern

### STAGE 1: Compile Visualization Service
ARG APPLICATION_ENVIRONMENT
RUN if [ -z "$APPLICATION_ENVIRONMENT" ]; then echo 'Environment variable APPLICATION_ENVIRONMENT must be set.'; exit 1; fi

# Copy lock file and package manifest
COPY ./package*.json ./

# Install dependencies (with fallback logic)
RUN [ -d node_modules ] && echo "Using cached node_modules" || npm install --legacy-peer-deps --prefer-offline --no-audit


# Copy the rest of the application code
COPY . .

# Build the Angular application
RUN npm run build -- --configuration=${APPLICATION_ENVIRONMENT}

### STAGE 2: Build Visualization Image
FROM selidocker.seli.gic.ericsson.se/proj-lantern/base/angular-service:0.0.9

ARG APPLICATION_VERSION
ENV APPLICATION_VERSION=${APPLICATION_VERSION}

ARG BUILD_DIR=/lantern

# Setting default shell to bash
SHELL ["/bin/bash", "-c"]
LABEL maintainer="Ericsson"
EXPOSE 8080

WORKDIR /lantern

COPY --from=build ${BUILD_DIR}/dist/lantern-frontend/browser .
COPY --from=build ${BUILD_DIR}/nginx.conf.template .

RUN mv ./nginx.conf.template  /etc/nginx/conf.d/lantern.conf.template

RUN chown -R nginx:nginx /lantern
RUN chown -R nginx:nginx /etc/nginx

RUN touch /run/nginx.pid
RUN chown -R nginx:nginx /run/nginx.pid

USER nginx

CMD ["/lantern/start-service.sh"]
