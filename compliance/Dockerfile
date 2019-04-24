FROM node:6-alpine

RUN npm install -g gitbook-cli
RUN apk --no-cache add curl git

WORKDIR /cm
RUN curl -L https://github.com/opencontrol/compliance-masonry/releases/download/v1.1.6/compliance-masonry_1.1.6_linux_amd64.tar.gz -o compliance-masonry.tar.gz
RUN tar -xf compliance-masonry.tar.gz

# Copy sources
WORKDIR /app
COPY . .

WORKDIR /app/compliance
RUN /cm/compliance-masonry get
RUN /cm/compliance-masonry docs gitbook LATO

WORKDIR /app/compliance/exports
EXPOSE 4000
ENTRYPOINT ["gitbook", "serve"]
