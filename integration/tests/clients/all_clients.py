import uuid

from . import consul
from . import dummy
from . import events
from . import wiremock


# pylint: disable=too-many-instance-attributes
class Clients:

    def __init__(self, num_of_clusters=1):
        self.clusters = [self.Cluster(i) for i in range(num_of_clusters)]
        self.consul_thalos = consul.Client('consul-thalos', 'http://consul-thalos:8500')

    class Cluster:
        def __init__(self, i):
            timeout = 5
            self.name = 'thalos{}'.format(i)
            self.id = str(uuid.uuid5(uuid.NAMESPACE_DNS, self.name))
            self.wiremock = wiremock.Client('wiremock{}'.format(i))
            self.events = events.Client('wiremock{}'.format(i), 'http://events-agent{}'.format(i))
            self.dummy = dummy.Client(
                'dummy', 'http://dummy{}'.format(i), timeout=timeout)

        def wait(self):
            pass
