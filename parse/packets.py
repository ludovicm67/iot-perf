from pathlib import Path
from scapy.all import IPv6, load_contrib, wrpcap
import re
load_contrib('coap')

IN_REGEX = re.compile(r'^after decompression \d+:(?P<packet>[0-9a-f]+)$')
OUT_REGEX = re.compile(r'^before compression \(\d+\): (?P<packet>[0-9a-f]+)$')
def from_logs(path):
    path = Path(path)

    with path.open() as file:
        for line in file:
            [ts, rest] = line.split('\t')
            rest = rest.strip()
            match = IN_REGEX.match(rest)
            if match is not None:
                yield (False, int(ts), bytes.fromhex(match.group('packet')))
                continue

            match = OUT_REGEX.match(rest)
            if match is not None:
                yield (True, int(ts), bytes.fromhex(match.group('packet')))

def parse(packets):
    for (out, ts, packet) in packets:
        packet = IPv6(packet)
        packet.time = ts
        yield (out, packet)

if __name__ == '__main__':
    import sys
    packets = from_logs(sys.argv[1])
    wrpcap(sys.argv[2], (packet for (out, packet) in parse(packets)))
