#! /usr/bin/env python3

import argparse
import getpass
import os
import shutil
import subprocess
import sys
import tempfile


program_dir = os.path.dirname(sys.argv[0])


def parse_args():
    parser = argparse.ArgumentParser(description='Online backup to '
            + 'Google App Engine, GitHub or a git repository.')
    parser.add_argument('src', help='Source (directory to backup)')
    parser.add_argument('dest', choices=['appengine', 'github', 'git'],
            help='Destination (one of %(choices)s)')
    parser.add_argument('--preprocess-tool', metavar='tool',
            help='Program invoked with a copy of the source directory as its '
            + 'single argument, before uploading to the destination')

    gae_group = parser.add_argument_group('Google App Engine')
    gae_group.add_argument('--appengine-app-id', metavar='app_id')
    gae_group.add_argument('--appengine-email', metavar='email')
    gae_group.add_argument('--appengine-version', metavar='version')

    github_group = parser.add_argument_group('GitHub')
    github_group.add_argument('--github-push-url', metavar='url')
    github_group.add_argument('--github-branch', metavar='branch')
    github_group.add_argument('--github-commit-message', metavar='msg')
    github_group.add_argument('--github-dns-cname', metavar='cname',
            help='optional DNS CNAME')

    git_group = parser.add_argument_group('Git')
    git_group.add_argument('--git-push-url', metavar='url')
    git_group.add_argument('--git-branch', metavar='branch')
    git_group.add_argument('--git-commit-message', metavar='msg')

    return parser.parse_args()


class Destination:

    def __init__(self, path):
        self.path = path

    def upload(self):
        raise NotImplementedError('Subclasses must implement this method')


def getDestination(args, path):
    '''Factory method for Destination from the program args'''

    if args.dest == 'appengine':
        return GoogleAppEngineDest(path, args.appengine_app_id,
                args.appengine_email, args.appengine_version)
    elif args.dest == 'git':
        return GitDest(path, args.git_push_url, args.git_branch,
                args.git_commit_message)
    elif args.dest == 'github':
        return GitHubDest(path, args.github_push_url, args.github_branch,
                args.github_commit_message, args.github_dns_cname)
    else:
        raise ValueError('Unexpected destination "' + args.dest + '"')


class GoogleAppEngineDest(Destination):

    def __init__(self, path, appid, email, version):
        super().__init__(path)
        if not appid or not email or not version:
            raise ValueError('Incomplete args for Google App Engine')
        self.appid = appid
        self.email = email
        self.version = version

    def addWebInf(self):
        webinf = os.path.join(self.path, 'WEB-INF')
        os.mkdir(webinf)
        shutil.copy(os.path.join(program_dir, 'web.xml'), webinf)
        shutil.copy(os.path.join(program_dir, 'appengine-web.xml'), webinf)

    def upload(self):
        self.addWebInf()
        passwd = getpass.getpass()
        p = subprocess.Popen(['appcfg.sh', '--no_cookies', '--passin',
            '-A', self.appid, '-e', self.email, '-V', self.version,
            'update', self.path],
            stdin = subprocess.PIPE)
        p.communicate(bytes(passwd, 'utf-8'))
        p.stdin.close()
        if p.wait():
            raise Exception('appcfg.sh failed')


class GitDest(Destination):

    def __init__(self, path, pushUrl, branch, commitMsg):
        super().__init__(path)
        if not pushUrl or not branch or not commitMsg:
            raise ValueError('Incomplete args for Git')
        self.pushUrl = pushUrl
        self.branch = branch
        self.commitMsg = commitMsg

    def commit(self):
        subprocess.check_call(['git', 'init'], cwd=self.path)
        subprocess.check_call(['git', 'add', '.'], cwd=self.path)
        subprocess.check_call(['git', 'commit', '-m', self.commitMsg],
                cwd=self.path)

    def push(self):
        subprocess.check_call(['git', 'push', self.pushUrl,
            '+master:' + self.branch], cwd=self.path)

    def upload(self):
        self.commit()
        self.push()


class GitHubDest(GitDest):

    def __init__(self, path, pushUrl, branch, commitMsg, cname):
        super().__init__(path, pushUrl, branch, commitMsg)
        self.cname = cname

    def upload(self):
        if self.cname:
            with open(os.path.join(self.path, 'CNAME'), mode='x',
                    encoding='utf-8') as f:
                f.write(self.cname)
        super().upload()


if __name__ == '__main__':
    args = parse_args()
    with tempfile.TemporaryDirectory() as tmpdir:
        rootdir = shutil.copytree(args.src, os.path.join(tmpdir, 'a'))

        gitdir = os.path.join(rootdir, '.git')
        os.makedirs(gitdir, exist_ok=True)
        shutil.rmtree(gitdir)

        if args.preprocess_tool:
            subprocess.check_call([args.preprocess_tool, rootdir])

        dest = getDestination(args, rootdir)
        dest.upload()