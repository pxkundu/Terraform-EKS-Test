# ---- Stage 1: Build ----
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies (only package.json and package-lock.json first for better caching)
COPY apps/pt-notification-service/package*.json ./
COPY package*.json ../../
RUN npm install --legacy-peer-deps

# Copy source code
COPY apps/pt-notification-service ./
COPY tsconfig.base.json ./
COPY tsconfig.json ./

# Build the app (assumes NestJS/TypeScript)
RUN npm run build

# ---- Stage 2: Production ----
FROM node:18-alpine AS production

WORKDIR /app

# Copy only production dependencies
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Use a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the default NestJS port
EXPOSE 3000

# Start the application
CMD ["node", "dist/main.js"] 