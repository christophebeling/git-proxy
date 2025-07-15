# Stage 1: Build
FROM node:22-alpine AS build

# Set the working directory
WORKDIR /app

COPY . .

# Install the dependencies
RUN npm install

# Copy the rest of the application code

# Run the prepare script
RUN npm run prepare

RUN npm run build-tsc-prod

# Stage 2: Production
FROM node:20-alpine

# Set the working directory
WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist/index.js ./index.js
COPY --from=build /app/certs ./certs
COPY --from=build /app/dist/src ./src
COPY --from=build /app/proxy.config.json /app/proxy.config.json
COPY --from=build /app/config.schema.json /app/config.schema.json

# Expose the port the app runs on
EXPOSE 8080

# Set the environment variable for production
ENV NODE_ENV=production

RUN mkdir /app/.remote && chmod 777 /app/.remote
RUN mkdir /app/.data && chmod 777 /app/.data

# Run the server script
CMD ["node", "index.js"]
