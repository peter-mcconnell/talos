import json

from . import wiremock


class Client(wiremock.Client):

    def assert_submit(self, test, want_type_ids):
        """
        :param test: TestCase instance
        :param want_type_ids: a list of type_id that should be expected in the events/submit query
        """
        got_type_ids = self.get_submitted_events()
        test.assertSetEqual(set(want_type_ids), set(got_type_ids))

    def assert_register(self, test, want_count):
        """
        :param test: TestCase instance
        :param want_count: how many times events/register was expected to be called
        """
        count = self.get_registered_events()
        test.assertEqual(want_count, count)

    def get_submitted_events(self):
        got = self.get_requests('POST', '/api/v2/events/submit')
        got_type_ids = [json.loads(g['body'])['type_id'] for g in got]
        return got_type_ids

    def get_registered_events(self):
        return self.get_requests_count('POST', '/api/v2/events/register')
