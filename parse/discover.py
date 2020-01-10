import sys
from pathlib import Path

from config import parse_config


def discover(root):
    root = Path(root)
    for path in root.glob('*/config'):
        if path.parent.is_symlink():
            continue
        config = parse_config(path)
        firmware = Path(config['firmware_nd'])
        yield firmware.parts[1], path.parent

def group(iterable):
    entries = {}
    for (type, path) in iterable:
        entries[type] = entries.get(type, []) + [path]
    return entries

if __name__ == '__main__':
    print(group(discover(sys.argv[1])))
