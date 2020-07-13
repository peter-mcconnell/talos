import http

from .. import base
from .. import clients as _clients


class TestDummys(base.Base):
    def test_dummys(self):
        # default number of cluster is 1, we need to recreate the clients for the NB of clusters
        self.clients = _clients.Clients(num_of_clusters=2)
        for cluster in self.clients.clusters:
            res = self.assert_status(http.HTTPStatus.OK, cluster.dummy.get_hello, "user").json()
            self.assertEqual({"greetings": "user"}, res)
