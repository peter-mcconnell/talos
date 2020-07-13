from . import client


class Client(client.Client):

    def get_hello(self, user):
        return self._get('/api/hello/{}'.format(user))
