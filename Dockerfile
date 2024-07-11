# Stage 1: Build
FROM node:20-alpine AS build

# Set the working directory
WORKDIR /app

COPY . .

# Install the dependencies
RUN npm install

# Copy the rest of the application code

# Run the prepare script
RUN npm run prepare

RUN npm run build

# Stage 2: Production
FROM node:20-alpine

# Set the working directory
WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/index.js ./index.js
COPY --from=build /app/src ./src
COPY --from=build /app/proxy.config.json /app/proxy.config.json
COPY --from=build /app/config.schema.json /app/config.schema.json


# Expose the port the app runs on
EXPOSE 3000

# Set the environment variable for production
ENV NODE_ENV=production

# Run the server script
CMD ["npm", "run", "server"]
