# syntax=docker/dockerfile:1
FROM node:20-bookworm-slim AS build
ENV NODE_ENV=production
WORKDIR /app

# Toolchain pra node-gyp (Swiss Ephemeris)
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 make g++ git \
 && rm -rf /var/lib/apt/lists/*

# Copie package.json e (se existir) package-lock.json
COPY package.json ./
COPY package-lock.json* ./

# Se tiver lockfile -> npm ci; senão -> npm install
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      npm install --omit=dev; \
    fi

# Copiar código
COPY . .

# Garante só deps de produção no artefato
RUN npm prune --omit=dev

# Runtime
FROM node:20-bookworm-slim
ENV NODE_ENV=production
ENV PORT=3000
WORKDIR /app

COPY --from=build /app /app

# Healthcheck (requer rota /health no app)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
  CMD node -e "const http=require('http');http.get({host:'127.0.0.1',port:process.env.PORT||3000,path:'/health'},r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"
EXPOSE 3000
CMD ["node","index.js"]
