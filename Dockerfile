FROM node:12

WORKDIR /app

COPY ./app/package.json /app
#COPY ./app/package-lock.json* /app

ARG NPM_TOKEN
RUN npm config set registry http://registry.npmjs.org/ && \
    echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc

RUN npm install

COPY ./app/ /app/

ARG PORT

EXPOSE ${PORT}

CMD ["npm", "start"]
