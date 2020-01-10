import sys
from pathlib import Path
from collections import namedtuple
from enum import Enum
from datetime import datetime
from netaddr import IPAddress, IPNetwork

class Config(namedtuple('Config', 'nodes gateway network timings prefix')):
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

        return Config(
            nodes,
            gateway,
            network,
            timings,
            prefix,
        )

class NodeType(Enum):
    BORDER_ROUTER = 1
    COAP_SERVER = 2

class Node(namedtuple('Node', 'uid num type logfile consumption')):
    def ip(self, prefix):
        return prefix | IPAddress('::' + self.uid)

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
