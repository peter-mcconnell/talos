import copy
import logging
import socket

import requests
import waiting

logging.basicConfig(stream=logging.sys.stdout, level=logging.DEBUG)


class Client:
    LOG = logging.getLogger(__name__)

    def __init__(self, container_name, url=None, timeout=None):
        self.container_name = container_name
        self.url = url or 'http://{}'.format(container_name)
        self._timeout = timeout or 5
        self.session = requests.Session()

    def wait(self, timeout=20):
        waiting.wait(
            self.is_active,
            timeout_seconds=timeout,
            waiting_for='Service {} on URL {}'.format(self.container_name, self.url)
        )

    def is_active(self):
        try:
            self._get()
        except requests.HTTPError:
            return True
        except Exception:  # pylint: disable=broad-except
            return False
        else:
            return True

    @property
    def ip(self):
        try:
            addresses = socket.getaddrinfo(self.container_name, None)
            return next(
                address for address in addresses
                if address[1] == socket.SOCK_STREAM
            )[-1][0]
        except Exception as exc:
            self.LOG.error('Failed fetching client IP for service: %s %s', self.container_name, exc)
            raise exc

    def copy(self):
        new_client = type(self)(self.container_name, self.url)
        new_client.session.headers = copy.deepcopy(self.session.headers)
        new_client.session.cookies = copy.deepcopy(self.session.cookies)
        return new_client

    def reset(self):
        headers = copy.deepcopy(self.session.headers)
        cookies = copy.deepcopy(self.session.cookies)
        self.session = requests.Session()
        self.session.headers = headers
        self.session.cookies = cookies

    def _get(self, path='', **kwargs):
        self._update_kwargs(kwargs)
        return self.session.get(self.url + path, **kwargs)

    def _delete(self, path='', **kwargs):
        self._update_kwargs(kwargs)
        return self.session.delete(self.url + path, **kwargs)

    def _post(self, path='', **kwargs):
        self._update_kwargs(kwargs)
        return self.session.post(self.url + path, **kwargs)

    def _put(self, path='', **kwargs):
        self._update_kwargs(kwargs)
        return self.session.put(self.url + path, **kwargs)

    def _patch(self, path='', **kwargs):
        self._update_kwargs(kwargs)
        return self.session.patch(self.url + path, **kwargs)

    def _head(self, path='', **kwargs):
        self._update_kwargs(kwargs)
        return self.session.head(self.url + path, **kwargs)

    def options(self, path='', **kwargs):
        self._update_kwargs(kwargs)
        return self.session.options(self.url + path, **kwargs)

    def _update_kwargs(self, kwargs):
        kwargs.setdefault('timeout', self._timeout)
