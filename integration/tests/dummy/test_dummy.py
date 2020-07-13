import http

from .. import base


class TestDummy(base.Base):
    def test_dummy(self):
        for cluster in self.clients.clusters:
            res = self.assert_status(http.HTTPStatus.OK, cluster.dummy.get_hello, "user").json()
            self.assertEqual({"greetings": "user"}, res)
