import sys
from pathlib import Path
from collections import namedtuple
from enum import Enum
from datetime import datetime
from netaddr import IPAddress, IPNetwork

Config = namedtuple('Config', 'nodes gateway prefix timings')

class NodeType(Enum):
    BORDER_ROUTER = 1
    COAP_SERVER = 2

class Node(namedtuple('Node', 'uid num type')):
    def ip(self, prefix):
        return prefix | IPAddress('::' + self.uid)

Timings = namedtuple('Timings', 'start coap_get coap_observe')

def parse_config(path):
    config = {}
    with Path(file).open('r') as f:
        for line in f:
            [key, value] = line.split('\t')
            config[key.strip()] = value.strip()
    return config

def transform_config(config):
    uid_map = {}
    u = config['uid_map'].split(' ')
    prefix = IPNetwork('2001:660:4701:f0b1::/64')
    for i in range(int(len(u) / 2)):
        uid_map[u[i * 2]] = u[i * 2 + 1]
    print(uid_map)

    nodes = []
    for num in config['nodes'].split(' '):
        nodes.append(Node(
            uid_map['m3-' + num],
            int(num),
            NodeType.COAP_SERVER
        ))

    gateway = Node(
        uid_map['m3-' + config['gateway']],
        int(config['gateway']),
        NodeType.BORDER_ROUTER
    )

    timings = Timings(
        start=datetime.utcfromtimestamp(int(config['start'])),
        coap_get=datetime.utcfromtimestamp(int(config['coap_get_timestamp'])),
        coap_observe=datetime.utcfromtimestamp(int(config['coap_observe_timestamp'])),
    )

    return Config(
        nodes,
        gateway,
        prefix,
        timings
    )

if __name__ == '__main__':
    file = sys.argv[1]
    config = parse_config(file)
    print(config)
    print(transform_config(config))
