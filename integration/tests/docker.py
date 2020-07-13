import collections
import contextlib
import json
import logging
import subprocess
import typing

import yaml
from compose.cli import command as compose_command
from docker.client import APIClient

LOG = logging.getLogger(__name__)


class DockerFailedException(Exception):
    pass


class Docker:
    """
    A controller for docker and docker-compose command for test environments.
    Provides utilities to execute docker and docker-compose commands,
    and for starting/stopping of containers and connecting/disconnecting of
    containers from docker networks.
    """

    COMPOSE_FILE = '/docker-compose.yml'

    def __init__(self):
        """
        Creates a new docker controller
        """
        self.client = APIClient()
        self.compose_run_name = compose_command.get_project_name('.')
        self.services, networks = self._load_compose_yaml()
        self.networks = {
            network: '{}_{}'.format(self.compose_run_name, network)
            for network in networks
        }

    def compose(self, action, services=None, *args):
        """
        Runs a docker-compose command
        :param action: docker-compose command, or list of commands
            for example 'run', or ['run', '--rm']
        :param services: a name of service or list of services
        :param args: arguments to pass to the end of the command
        """
        services = self._to_list(services)
        action = self._to_list(action)
        return self._subprocess(['docker-compose'] + action + services + list(args))

    def execute(self, service, *args):
        """
        Runs docker-compose exec on a service
        :param service: which service to execute on
        :param args: commands to execute
        """
        return self.compose('exec', '-T', service, *args)

    def execute_with_TTY(self, service, *args):
        """
        Runs docker-compose exec on a service
        :param service: which service to execute on
        :param args: commands to execute
        """
        return self.compose('exec', service, *args)

    def docker(self, action, services=None, *args):
        """
        Runs a docker command
        :param action: docker command
        :param services: a name of service (in the docker-compose notion) or list of those
        :param args: arguments to pass to the command
        """
        action = self._to_list(action)
        services = self._to_list(services) or self.services.keys()
        out = {}
        for name, service_id in self._get_service_ids(services).items():
            out[name] = self._subprocess(['docker'] + action + [service_id] + list(args))
        return out

    def inspect(self, service: str):
        """
        Get information of a container
        :param service: name of docker-compose service
        """
        return json.loads(self.docker('inspect', service)[service])[0]

    def connect(self, service_map=None):
        """
        Connect services to networks
        @param service_map: a string or list or map of services to a string or list or map
        of networks to a string or list network aliases
        """
        services = self._to_dict(service_map) or dict.fromkeys(self.services.keys())
        for service in services:
            networks = service_map.get(service, self.get_service_networks(service))
            for network, aliases in networks.items():
                LOG.info(
                    'Connecting container %s to network %s with aliases: %s',
                    service, network, aliases)
                aliases_command = []
                for alias in aliases:
                    aliases_command += ['--alias', alias]
                self.docker(['network', 'connect'] + aliases_command + [network], [service])

    def disconnect(self, service_map=None):
        """
        Disconnect services from networks
        After disconnecting of a network, the client session must be reset.
        @param service_map: a dict from service name to a list or network name
        """
        aliases = collections.defaultdict(dict)
        services = self._to_dict(service_map) or dict.fromkeys(self.services.keys())
        for service, networks in services.items():
            inspect = self.inspect(service)
            inspect_networks = inspect['NetworkSettings']['Networks']

            if networks is None:
                networks = inspect_networks
            else:
                networks = [self.networks[network] for network in self._to_list(networks)]

            for network in networks:
                aliases[service][network] = inspect_networks[network]['Aliases']
                LOG.info('Disconnecting container %s from network %s', service, network)
                self.docker(['network', 'disconnect', network], [service])
        return dict(aliases)

    @contextlib.contextmanager
    def net_delay(self, container_name: str, delay_ms: int):
        """
        add a fixed amount of delay to all packets going out from the given container.
        :param container_name:
        :param delay_ms:
        :return:
        """
        # container with the "tc" command.
        tc_img = 'gaiadocker/iproute2'
        cid = self.inspect(container_name)['Id']
        # use the container’s network stack.
        hconfig = self.client.create_host_config(auto_remove=True, cap_add='NET_ADMIN',
                                                 network_mode='container:{}'.format(cid))
        try:
            cmd = 'qdisc add dev eth0 root netem delay {}ms'.format(delay_ms)
            self.client.start(self.client.create_container(tc_img, host_config=hconfig, command=cmd)['Id'])
            yield
        finally:
            self.client.start(self.client.create_container(tc_img, host_config=hconfig,
                                                           command='qdisc del dev eth0 root netem')['Id'])

    @contextlib.contextmanager
    def disconnected(self, service_map):
        """
        A context manager for temporary disconnect services from networks.
        @param service_map: a dict from service name to a list or network name
        """
        aliases = {}
        try:
            aliases = self.disconnect(service_map)
            yield
        finally:
            if aliases:
                self.connect(aliases)

    @contextlib.contextmanager
    def stopped(self, services):
        """
        A context manager for having containers in state stopped
        """
        try:
            self.compose('stop', services)
            yield
        finally:
            self.compose('start', services)

    def get_service_networks(self, service):
        """
        Get the networks of a service, with all the aliases in that network
        @param service: a service name
        """
        networks = self._to_dict(self.services[service]['networks'])
        default_aliases = [service]
        network_map = {}
        for name, config in networks.items():
            if not config:
                network_map[name] = default_aliases
            else:
                network_map[name] = config.get('aliases', default_aliases)
        return network_map

    def _get_service_ids(self, services):
        return {
            name: self.compose(["ps", "-q"], name)
            for name in self._to_list(services)
        }

    @staticmethod
    def _subprocess(command: typing.List[str]) -> str:
        LOG.info('Running command %s', ' '.join(command))
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = process.communicate()
        if process.returncode != 0:
            raise DockerFailedException("Failed running command {}: {}".format(command, err))
        return out.decode().strip()

    def _load_compose_yaml(self):
        with open(self.COMPOSE_FILE, 'r') as compose_file:
            test = yaml.load(compose_file)
        return test['services'], test.get('networks', {}).keys()

    @staticmethod
    def _to_list(obj) -> typing.List:
        if obj is None:
            return []
        if not isinstance(obj, list):
            obj = [obj]
        return obj

    @staticmethod
    def _to_dict(obj) -> typing.Dict:
        if obj is None:
            return {}
        if not isinstance(obj, dict):
            obj = dict.fromkeys(obj)
        return obj
