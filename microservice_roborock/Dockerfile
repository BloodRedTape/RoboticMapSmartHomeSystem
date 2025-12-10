FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV BACKEND_URL=http://backend:8080
ENV LISTEN_HOST=0.0.0.0
ENV LISTEN_PORT=5584
ENV ROBOROCK_USERNAME=""
ENV ROBOROCK_PASSWORD=""

EXPOSE 5584

CMD ["python", "main.py"]
