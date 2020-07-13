#!/usr/local/bin/python3
from retrying import retry
import requests
import base64
import time
import os

THALOS_CONSUL_URL = os.environ.get("THALOS_CONSUL_URL", None)

# Retry with 20 second timeout, 2 second interval
@retry(stop_max_delay=20000, wait_fixed=2000)
def consul_set_string(consul_url, prefix, key, value):
    if consul_url is None:
        return
    resp = requests.put("/".join([consul_url, "v1", "kv", prefix, key]), data=value)
    if resp.content != b"true":
        raise Exception("Consul write returned %s" % resp.content)

def consul_set_file(consul_url, prefix, key, file):
    with open(file, 'rb') as f:
        contents = f.read()
    consul_set_string(consul_url, prefix, key, contents)

def consul_set_file_env(consul_url, prefix, key, file):
    with open(file, 'rb') as f:
        encoded = base64.b64encode(f.read())
    consul_set_string(consul_url, prefix, key, encoded)

def configure():
    print("Setting up consul environment")

    # DO SOMETHING HERE

    print(" > Finished setting consul")

if __name__ == "__main__":
    configure()
