import logging

from . import client

LOG = logging.getLogger(__name__)


class Client(client.Client):

    def add_request_mapping(self, data):
        response = self._post('/__admin/mappings', json=data)
        response.raise_for_status()

    def get_requests_count(self, method, pattern):
        response = self._post(
            '/__admin/requests/count',
            json={'method': method, 'urlPattern': pattern}
        )
        response.raise_for_status()
        return response.json()['count']

    def get_requests(self, method, pattern):
        response = self._post(
            '/__admin/requests/find',
            json={'method': method, 'urlPattern': pattern}
        )
        response.raise_for_status()
        return response.json()['requests']

    def reset(self):
        response = self._post('/__admin/requests/reset')
        response.raise_for_status()
        return response
