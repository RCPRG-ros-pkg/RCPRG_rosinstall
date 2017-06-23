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

def isGitRepo(path):
    with open(os.devnull, 'w') as FNULL:
        is_repo = (subprocess.call(['git', 'status'], stdout=FNULL, stderr=FNULL, cwd=path) == 0)
    return is_repo

def getGitBranch(path):
    out_read, out_write = os.pipe()
    subprocess.call(['git', 'rev-parse', "--abbrev-ref", 'HEAD'], stdout=out_write, cwd=path)
    branch_str = os.read(out_read, 1000)
    os.close(out_read)
    return branch_str

def getGitRemoteUrl(path):
    out_read, out_write = os.pipe()
    subprocess.call(['git', 'remote', "get-url", 'origin'], stdout=out_write, cwd=path)
    url_str = os.read(out_read, 1000)
    os.close(out_read)
    return url_str

def getGitChanges(path):
    out_read, out_write = os.pipe()
    subprocess.call(['git', 'status'], stdout=out_write, cwd=path)
    status_str = os.read(out_read, 1000)
    os.close(out_read)
    if status_str.strip().endswith("nothing to commit, working directory clean"):
        status_str = None

    return status_str

    print "getGitChanges 1"
    out_read, out_write = os.pipe()
    subprocess.call(['git', 'diff-index', "HEAD", '--'], stdout=out_write, cwd=path)
    diff_str = os.read(out_read, 1000)
    os.close(out_read)

    print "getGitChanges 2"
    out_read, out_write = os.pipe()
    subprocess.call(['git', 'ls-files', "--others", '--exclude-standard'], stdout=out_write, cwd=path)
    untracked_str = os.read(out_read, 1000)
    os.close(out_read)
    print "getGitChanges 3"

    if len(diff_str) == 0:
        diff_str = None
    if len(untracked_str) == 0:
        untracked_str = None
    return (diff_str, untracked_str)

def isHgRepo(path):
    with open(os.devnull, 'w') as FNULL:
        is_repo = (subprocess.call(['hg', 'status'], stdout=FNULL, stderr=FNULL, cwd=path) == 0)
    return is_repo

def getHgTag(path):
    out_read, out_write = os.pipe()
    subprocess.call(['hg', 'id', "-t"], stdout=out_write, cwd=path)
    branch_str = os.read(out_read, 1000)
    os.close(out_read)
    return branch_str

def getHgUrl(path):
    out_read, out_write = os.pipe()
    subprocess.call(['hg', 'paths', "default"], stdout=out_write, cwd=path)
    url_str = os.read(out_read, 1000)
    os.close(out_read)
    return url_str

def recursiveFindRepositories(path, repo_list):
    if isGitRepo(path) or isHgRepo(path):
        repo_list.append(path)
        return

    subdirs = next(os.walk(path))[1]
    for d in subdirs:
        recursiveFindRepositories(path + "/" + d, repo_list)

def main(argv):
    usage_str = 'test.py [-i <rosinstallfile>]'
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
        # scan subdirectories
        repo_list = []
        dirs = next(os.walk("."))[1]
        for d in dirs:
            subdirs = next(os.walk("./" + d))[1]
            if "src" in subdirs:
                recursiveFindRepositories("./" + d + "/src", repo_list)

        changes_list = {}

        for path in repo_list:
            if isGitRepo(path):
                repo = "git"
                uri = getGitRemoteUrl(path)
                version = getGitBranch(path)
                changes = getGitChanges(path)
            elif isHgRepo(path):
                repo = "hg"
                uri = getHgUrl(path)
                version = getHgTag(path)
                changes = None  # TODO
            else:
                raise
            if path.startswith("./"):
                p = path[2:]
            else:
                p = path
            print "- %s: {local-name: %s, uri: '%s', version: '%s'}"%(repo, p, uri.strip(), version.strip())
            if changes:
                changes_list[path] = changes

        print "# some packages contain local changes:"
        for ch in changes_list:
            print "#", ch
        exit(0)

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
        print "- %s: {local-name: %s, uri: '%s', version: '%s'}"%(r.type, r.local_name, r.uri, r.commit_sha)

#- git: {local-name: underlay_isolated/src/gazebo/dart,              uri: 'https://github.com/dartsim/dart.git', version: 'release-4.3'}
#- hg:  {local-name: underlay_isolated/src/gazebo/ign-math,          uri: 'https://bitbucket.org/ignitionrobotics/ign-math', version: 'ignition-math2_2.4.0'}


if __name__ == "__main__":
   main(sys.argv[1:])

