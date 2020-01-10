import sys
import re
from pathlib import Path
from collections import namedtuple
from enum import Enum
from datetime import datetime
from netaddr import IPAddress, IPNetwork
from pandas import DataFrame
import numpy as np

ROUTES_RE = re.compile(r'^(?P<destination>[0-9a-z:]+/\d+)\s+\(via (?P<via>[0-9a-z:]+)\)\s+(?P<timeout>\d+)s$')
NEIGHBOR_RE = re.compile(r'^(?P<address>[0-9a-z:]+)$')

Route = namedtuple('Route', 'destination via timeout')


class RPL(namedtuple('RPL', 'neighbors routes')):
    def parse_stream(file):
        groups = {}
        for line in file:
            [ts, rest] = line.split('\t')
            body = groups.get(ts, '')
            groups[ts] = body + '\n' + rest

        rpl = {}
        for ts, body in groups.items():
            rpl[int(ts)] = RPL.parse(body)
        return rpl

    def parse(body):
        neighbors = []
        routes = []
        for line in body.split('\n'):
            match = NEIGHBOR_RE.match(line)
            if match is not None:
                neighbors.append(IPAddress(match.group('address')))

            match = ROUTES_RE.match(line)
            if match is not None:
                neighbors.append(Route(
                    IPNetwork(match.group('destination')),
                    IPAddress(match.group('via')),
                    int(match.group('timeout'))
                ))
        return RPL(neighbors, routes)


class Config(namedtuple('Config', 'nodes gateway network timings rpl prefix')):
    def load(prefix):
        prefix = Path(prefix)
        config = parse_config(prefix / 'config')
        uid_map = {}
        u = config['uid_map'].split(' ')
        network = IPNetwork('2001:660:4701:f0b1::/64')
        for i in range(int(len(u) / 2)):
            uid_map[u[i * 2]] = u[i * 2 + 1]

        def load_node(num, type):
            return Node(
                uid_map['m3-' + num],
                int(num),
                type,
                prefix / ('m3-' + num),
                prefix / 'consumption' / ('m3_' + num + '.oml')
            )

        nodes = []
        for num in config['nodes'].split(' '):
            nodes.append(load_node(num, NodeType.COAP_SERVER))

        gateway = load_node(config['gateway'], NodeType.BORDER_ROUTER)

        timings = Timings(
            start=datetime.utcfromtimestamp(int(config['start'])),
            coap_get=datetime.utcfromtimestamp(int(config['coap_get_timestamp'])),
            coap_observe=datetime.utcfromtimestamp(int(config['coap_observe_timestamp'])),
        )

        rpl = RPL.parse_stream((prefix / 'rpl.html').open())

        return Config(
            nodes,
            gateway,
            network,
            timings,
            rpl,
            prefix,
        )


class NodeType(Enum):
    BORDER_ROUTER = 1
    COAP_SERVER = 2


class Node(namedtuple('Node', 'uid num type logfile consumption')):
    def ip(self, prefix):
        return prefix | IPAddress('::' + self.uid)
    
    def conso_dataframe(self):
        with self.consumption.open() as conso_file:
            fields = [
                ('timestamp', float),
                ('type', np.str_, 16),
                ('num', int),
                ('t_s', int),
                ('t_us', int),
                ("power", float),
                ("voltage", float),
                ("current", float),
            ]
            names = [entry[0] for entry in fields]
            data = np.genfromtxt(conso_file, skip_header=9, names=names,
                                dtype=fields,
                                invalid_raise=False)
            return DataFrame(data)


Timings = namedtuple('Timings', 'start coap_get coap_observe')

def parse_config(path):
    config = {}
    with Path(path).open('r') as f:
        for line in f:
            [key, value] = line.split('\t')
            config[key.strip()] = value.strip()
    return config

if __name__ == '__main__':
    file = sys.argv[1]
    print(Config.load(file))
