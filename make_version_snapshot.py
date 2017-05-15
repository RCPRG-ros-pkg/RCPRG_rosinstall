#!/usr/bin/env python
import sys, getopt, os, subprocess
import math
import copy

class Repository:
    def __init__(self):
        self.type = None
        self.local_name = None
        self.uri = None
        self.commit_sha = None

def main(argv):
    usage_str = 'test.py -i <rosinstallfile>'
    rosinstallfile = None
    try:
        opts, args = getopt.getopt(argv,"hi:",["rosinstallfile="])
    except getopt.GetoptError:
        print usage_str
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print usage_str
            sys.exit(0)
        elif opt in ("-i", "--rosinstallfile"):
            rosinstallfile = arg

    if not rosinstallfile:
        print usage_str
        sys.exit(1)

    rosinstall_full_path = None
    repos = []
    with open(rosinstallfile, 'r') as f:
        rosinstall_full_path = os.path.realpath(f.name)

        ls = f.readlines()
        i = 0
        while i < len(ls):
            if ls[i].startswith('- hg:'):
                repos.append(Repository())
                repos[-1].type = "hg"
            elif ls[i].startswith('- git:'):
                repos.append(Repository())
                repos[-1].type = "git"
            else:
                if ls[i].startswith("    local-name:"):
                    repos[-1].local_name = ls[i][16:].strip()
                if ls[i].startswith("    uri:"):
                    repos[-1].uri = ls[i][9:].strip()
            i += 1

    if not rosinstall_full_path:
        print "could not open file", rosinstallfile
        sys.exit(3)

    workspace_dir = rosinstall_full_path[:rosinstall_full_path.rfind('/')]
#    print "workspace directory:", workspace_dir

    for r in repos:
        if r.type == "git":
            out_read, out_write = os.pipe()
            subprocess.call(['git', 'log', "--pretty=format:'%H'", '-n', '1'], stdout=out_write, cwd=workspace_dir + '/' + r.local_name)
            sha_str = os.read(out_read, 1000)
            os.close(out_read)
            r.commit_sha = sha_str.strip('\'')
        if r.type == "hg":
            out_read, out_write = os.pipe()
            subprocess.call(['hg', '--debug', "id", '-i'], stdout=out_write, cwd=workspace_dir + '/' + r.local_name)
            sha_str = os.read(out_read, 1000)
            os.close(out_read)
            r.commit_sha = sha_str.strip()

#    for r in repos:
#        print r.type, r.local_name, r.commit_sha

    for r in repos:
        print "- %s: {local-name: %s, uri: %s, version: '%s'}"%(r.type, r.local_name, r.uri, r.commit_sha)

#- git: {local-name: underlay_isolated/src/gazebo/dart,              uri: 'https://github.com/dartsim/dart.git', version: 'release-4.3'}
#- hg:  {local-name: underlay_isolated/src/gazebo/ign-math,          uri: 'https://bitbucket.org/ignitionrobotics/ign-math', version: 'ignition-math2_2.4.0'}


if __name__ == "__main__":
   main(sys.argv[1:])

