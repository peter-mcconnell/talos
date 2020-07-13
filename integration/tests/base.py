import functools
import logging
import os
import unittest
import uuid

import requests
import waiting
from dateutil import parser

from . import clients as _clients
from . import docker as _docker

logging.basicConfig(stream=logging.sys.stdout, level=logging.DEBUG)

LOG = logging.getLogger(__name__)
TTL = 60 * 60


class Base(unittest.TestCase):
    TIMEOUT = 10
    ENV_TEST = False

    docker = _docker.Docker()
    clients = _clients.Clients()

    def setUp(self):
        super().setUp()
        self.maxDiff = None  # pylint: disable=invalid-name

    def assert_status(self, status, func, *args, _msg='', **kwargs):
        try:
            response = func(*args, **kwargs)
        except requests.HTTPError as exc:
            response = exc.response
        self.assertEqual(
            response.status_code, status,
            'Invalid status code. Response text: {} {}'.format(response.text, _msg),
        )

        # override __bool__ method of response, so it will always return True
        # thus wait_on_assertion_error will finish even if response.status_code is
        # bigger than 400
        response.__bool__ = lambda _: True
        return response

    @staticmethod
    def wait_on_assertion_error(func, *args, timeout=10, **kwargs):
        do = functools.partial(func, *args, **kwargs)

        try:
            return waiting.wait(do, timeout, expected_exceptions=AssertionError)
        except waiting.exceptions.TimeoutExpired:
            # do once more, so the exception will be raised
            pass

        return do()

    @staticmethod
    def wait_on_connection_error(func, *args, timeout=10, **kwargs):
        def log_exception():
            try:
                return func(*args, **kwargs)
            except Exception as exc:
                logging.info('While waiting for %s(%s, %s) got exception %s',
                             func.__name__, args, kwargs, exc)
                raise

        return waiting.wait(log_exception, timeout, expected_exceptions=requests.exceptions.ConnectionError)

    @staticmethod
    def _parse_date_time(data_time: str) -> float:
        return parser.parse(data_time).timestamp()

    @staticmethod
    def _validate_uuid4(uuid_string):

        try:
            uuid.UUID(uuid_string, version=4)
            return True
        except ValueError:
            # If it's a value error, then the string
            # is not a valid hex code for a UUID.
            return False


def skip_long(func):
    @unittest.skipIf(not os.environ.get('SKIP_LONG_TESTS'), "long test")
    def run_func(self):
        return func(self)

    return run_func
