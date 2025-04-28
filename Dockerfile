# Use Node.js 20 Alpine base image
FROM node:20-alpine AS base

# Set environment variables
ENV NODE_ENV=production \
    PORT=6055 \
    DATABASE_URL=file:/data/database/data.db

# Install required system dependencies
RUN apk add --no-cache openssl sqlite

# Install dependencies stage
FROM base AS deps
WORKDIR /myapp
COPY package.json package-lock.json ./
RUN npm install --production=false

# Production dependencies stage
FROM base AS production-deps
WORKDIR /myapp
COPY --from=deps /myapp/node_modules /myapp/node_modules
COPY package.json package-lock.json ./
RUN npm prune --production

# Final production image
FROM base
WORKDIR /myapp

# Copy production node_modules
COPY --from=production-deps /myapp/node_modules /myapp/node_modules

# Copy application files
COPY . .

# Create database directory and ensure it's writable
RUN mkdir -p /data/database && \
    touch /data/database/data.db && \
    chmod -R a+rw /data/database

# Add shortcut for connecting to database CLI
RUN echo "#!/bin/sh\nset -x\nsqlite3 \$DATABASE_URL" > /usr/local/bin/database-cli && \
    chmod +x /usr/local/bin/database-cli

# Expose the port Directus runs on
EXPOSE 6055

# Start command (ensure start.sh exists and is executable)
CMD ["sh", "start.sh"]