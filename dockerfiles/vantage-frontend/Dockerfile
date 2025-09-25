FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY vantage/frontend/package*.json ./

# Install all dependencies (including dev dependencies needed for build)
RUN npm ci

# Copy source code
COPY vantage/frontend/ .

# Build the application
RUN npm run build

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]