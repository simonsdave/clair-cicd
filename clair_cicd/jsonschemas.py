import json
import os


def _load_jsonschema(schema_name):
    filename = os.path.join(
        os.path.dirname(__file__),
        'jsonschemas',
        '%s.json' % schema_name)

    with open(filename) as fp:
        return json.load(fp)


whitelist = _load_jsonschema('whitelist')

vulnerability = _load_jsonschema('vulnerability')
