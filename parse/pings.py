import re
from pathlib import Path
from netaddr import IPAddress
from pandas import DataFrame

RESPONSE_RE = re.compile(r'^(?P<bytes>\d*) bytes from (?P<address>[a-f0-9:]*)[:,].*icmp_seq=(?P<seq>\d+).*time=(?P<time>[0-9.]+)\s*ms$')
ERROR_RE = re.compile(r'^From (?P<address>[0-9a-f:]*) icmp_seq=(?P<seq>\d+)')
HEADER_RE = re.compile(r'^PING')

def parse_line(line):
    [ts, rest] = line.split('\t')

    if HEADER_RE.match(rest):
        return None

    match = RESPONSE_RE.match(rest)
    if match is not None:
        return [
            int(ts),
            IPAddress(match.group('address')),
            True,
            int(match.group('seq')),
            float(match.group('time')),
        ]

    if ERROR_RE.match(rest) is not None:
        return None

    raise Exception("Can't parse line line", rest)

def parse_file(file):
    for line in file:
        ret = parse_line(line.strip())
        if ret is not None:
            yield ret

def parse(path):
    path = Path(path)
    with path.open() as file:
        df = DataFrame(
            data=parse_file(file),
            columns=['timestamp', 'address', 'received', 'seq', 'time']
        )
        df = df.set_index('timestamp')
    return df

if __name__ == '__main__':
    import sys
    df = parse(sys.argv[1])
    print(df)
    print(df[df.received == True])

