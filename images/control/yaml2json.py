#!/usr/bin/python

import sys, yaml, json;

print json.dumps(yaml.load(sys.stdin.read()))
