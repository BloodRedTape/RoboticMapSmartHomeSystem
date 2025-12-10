FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

ENV MQTT_BROKER=mqtt://mosquitto:1883
ENV MQTT_BASE_TOPIC=zigbee2mqtt
ENV BACKEND_URL=http://backend:8080
ENV LISTEN_HOST=0.0.0.0
ENV LISTEN_PORT=5582

EXPOSE 5582

CMD ["node", "index.js"]
