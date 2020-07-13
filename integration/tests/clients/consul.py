from . import client


class Client(client.Client):
    def get(self, key, recurse=False):
        return self._get(path='/v1/kv/{}'.format(key), params={'recurse': recurse})

    def delete(self, key, recurse=False):
        return self._delete(path='/v1/kv/{}'.format(key), params={'recurse': recurse})

    def put(self, key, value):
        return self._put(path='/v1/kv/{}'.format(key), json=value)

    def put_data(self, key, value):
        return self._put(path='/v1/kv/{}'.format(key), data=value)
