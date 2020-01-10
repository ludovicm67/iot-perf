from operator import itemgetter
from pathlib import Path
import re
from netaddr import IPAddress, IPNetwork
import networkx as nx

ROUTE_REGEX = re.compile(r'^RPL: Adding default route through (?P<route>[0-9a-f:]+)')

def from_logs(path):
    path = Path(path)

    with path.open() as file:
        for line in file:
            [ts, rest] = line.split('\t')
            rest = rest.strip()
            match = ROUTE_REGEX.match(rest)
            if match is not None:
                yield (int(ts), IPAddress(match.group('route')))

def events(nodes):
    return sorted(_yield_events(nodes), key=itemgetter(0))

def to_graph(state):
    G = nx.DiGraph()
    for source, destination in state.items():
        G.add_node(source)
        G.add_edge(source, destination)
    return G

def is_converged(state, nodes):
    for node in nodes:
        ip = node.ip(IPNetwork('fe80::/64'))
        if ip not in state:
            return False
    return True

def first_converged(iterable, nodes):
    for (ts, state) in iterable:
        if is_converged(state, nodes):
            return ts
    return None

def states(iterable):
    graph = {}
    for (ts, source, destination) in iterable:
        graph[source] = destination
        yield ts, graph

def _yield_events(nodes):
    for node in nodes:
        ip = node.ip(IPNetwork('fe80::/64'))
        for ts, route in from_logs(node.logfile):
            yield ts, ip, route

if __name__ == '__main__':
    import sys
    from .config import Config
    config = Config.load(sys.argv[1])
    *_, (_, last) = states(events(config.nodes))
    print(last)

