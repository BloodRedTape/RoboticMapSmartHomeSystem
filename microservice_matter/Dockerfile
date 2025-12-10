FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV MATTER_SERVER_URL=ws://matter-server:5580/ws
ENV BACKEND_URL=http://backend:8080
ENV LISTEN_HOST=0.0.0.0
ENV LISTEN_PORT=5581

EXPOSE 5581

CMD ["python", "main.py"]
