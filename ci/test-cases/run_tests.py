#!/usr/bin/python3

import argparse
import os
import stat
import subprocess
import yaml

def run_fluster(codec, test_suite, skips, single_thread):
    print(f"  {codec} -> {test_suite} (skip: {skips})")
    cmd = ['python3', '/usr/bin/fluster_parser.py', '-ts', test_suite, '-d', f"ccdec-{codec}", '-t' '300']

    if single_thread:
        cmd.extend(['-j', '1'])
    if skips:
        for index, skip in enumerate(skips):
            cmd.extend(['-sv', skip] if not index else [skip])

    print(cmd)
    subprocess.run(cmd, check=False)

def retrieve_ccdec(build_id):
    try:
        if not os.path.exists("/opt/cros-codecs"):
            os.mkdir("/opt/cros-codecs")
        subprocess.run(['wget', '-O', '/opt/cros-codecs/ccdec', 'https://people.collabora.com/~detlev/cros-codecs-tests/ccdec'])
        os.chmod("/opt/cros-codecs/ccdec", mode=(stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO))
        os.environ['PATH'] = os.environ['PATH'] + ":/opt/cros-codecs"
    except Exception as e:
        print(e)

    cmd = []

# This should be an argument
run_arch='intel'
argparser = argparse.ArgumentParser()
argparser.add_argument('--arch', choices=['amd', 'intel'], help='Architecture', required=True)
argparser.add_argument('--config-file', help='Configuration file', required=True)
argparser.add_argument('--ccdec-build-id', help='ccded binary build id', required=True)
argparser.add_argument('--single', help='Run in a single thread', action='store_true')
args = argparser.parse_args()

retrieve_ccdec(args.ccdec_build_id)

with open(args.config_file, "r") as stream:
    try:
        config = yaml.safe_load(stream)
        for arch, arch_info in config.items():
            if arch != args.arch:
                continue
            device_type=arch_info['device_type']
            for c in arch_info['codecs']:
                for codec, test_suites in c.items():
                    for ts in test_suites['test-suites']:
                        for test_suite in ts:
                            skips=ts[test_suite]["skip-vectors"]
                            run_fluster(codec, test_suite, skips, args.single)
            break
                        
    except yaml.YAMLError as exc:
        print(exc)
