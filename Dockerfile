FROM node:20-alpine

# better-sqlite3 necesita build tools para compilar el módulo nativo
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copiar dependencias primero (capa cacheada)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copiar el resto del proyecto
COPY server.js ./
COPY public/ ./public/

# Crear directorio para la base de datos
RUN mkdir -p /app/data

# Volumen para persistir la DB entre deploys
VOLUME ["/app/data"]

EXPOSE 3000

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

CMD ["node", "server.js"]
