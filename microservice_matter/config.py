import os
from typing import Optional

class Config:
    def __init__(self):
        self.matter_server_url: str = os.getenv('MATTER_SERVER_URL', 'ws://localhost:5580/ws')
        self.backend_url: str = os.getenv('BACKEND_URL', 'http://localhost:8080')
        self.listen_host: str = os.getenv('LISTEN_HOST', '0.0.0.0')
        self.listen_port: int = int(os.getenv('LISTEN_PORT', '5581'))
        self.log_level: str = os.getenv('LOG_LEVEL', 'INFO')
        self.commission_timeout: int = int(os.getenv('COMMISSION_TIMEOUT', '300'))
        self.reconnect_interval: int = int(os.getenv('RECONNECT_INTERVAL', '5'))

config = Config()
