import os
from typing import Optional

class Config:
    def __init__(self):
        self.backend_url: str = os.getenv('BACKEND_URL', 'http://localhost:8080')
        self.listen_host: str = os.getenv('LISTEN_HOST', '0.0.0.0')
        self.listen_port: int = int(os.getenv('LISTEN_PORT', '5584'))
        self.log_level: str = os.getenv('LOG_LEVEL', 'INFO')

        self.roborock_username: str = os.getenv('ROBOROCK_USERNAME', '')
        self.roborock_password: str = os.getenv('ROBOROCK_PASSWORD', '')

        self.polling_interval: int = int(os.getenv('POLLING_INTERVAL', '5'))
        self.map_refresh_interval: int = int(os.getenv('MAP_REFRESH_INTERVAL', '30'))
        self.reconnect_interval: int = int(os.getenv('RECONNECT_INTERVAL', '5'))

config = Config()
