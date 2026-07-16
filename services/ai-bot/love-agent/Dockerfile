FROM hardcoreeng/base-slim:v20250916
WORKDIR /usr/src/app

RUN npm install -g pnpm@10

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

COPY package.json package.json

RUN pnpm install --no-lockfile
COPY ./lib .

EXPOSE 4012
CMD [ "node", "index.js" , "start"]
