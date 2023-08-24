#!/bin/env python3

import argparse
import jinja2
import os

# Devices to use on lava:
# Intel uses asus-cx9400-volteer (CPU: 11th Gen Intel(R) Core(TM) i7-1160G7 @ 1.20GHz)
# AMD uses the ASUS Chromebook Flip CM1(CM1400) (CPU: AMD 3015Ce with Radeon Graphics)
DEVICE_TYPES = {
    "intel": "hp-x360-12b-ca0010nr-n4020-octopus",
    "amd": "hp-11A-G6-EE-grunt"
}

def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument('--template', help='Input template file', required=True)
    argparser.add_argument('--test-branch', help='The branch being tested', default='main')
    argparser.add_argument('--test-repo', help='The repository being tested', required=True)
    argparser.add_argument('--arch', choices=['amd', 'intel'], help='Architecture', required=True)
    argparser.add_argument('--ccdec-build-id', help='ccdec build id', required=True)
    args = argparser.parse_args()

    env = jinja2.Environment(loader=jinja2.FileSystemLoader(os.path.dirname(args.template)),
                             undefined=jinja2.StrictUndefined)

    template = env.get_template(os.path.basename(args.template))

    print(template.render(ccdec_build_id=args.ccdec_build_id, arch=args.arch, device_type=DEVICE_TYPES[args.arch], test_branch=args.test_branch, repo_url=args.test_repo))


if __name__ == '__main__':
    main()

