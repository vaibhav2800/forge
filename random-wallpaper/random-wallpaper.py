#! /usr/bin/env python3

import argparse, subprocess, random, sys, os

def get_valid_args():
    """Parses cmd line args and returns the namespace or exits with an error"""

    parser = argparse.ArgumentParser(
            description='Set random wallpaper with probability of K out of N')
    parser.add_argument('-K', type=int, default=1,
            help='set the wallpaper K out of N times (default %(default)s)')
    parser.add_argument('-N', type=int, default=10,
            help='set the wallpaper K out of N times (default %(default)s)')
    parser.add_argument('trees', metavar='dir', nargs='+',
            help='list of directory trees containing image files')
    parser.add_argument('--style', choices=['scaled', 'zoom'],
            help='new resizing style for wallpaper')
    parser.add_argument('--link', metavar='LINK',
            help='make (or change) symlink %(metavar)s '
            'pointing to chosen file')

    args = parser.parse_args()
    if args.K < 0:
        print('K must be >= 0', file=sys.stderr)
        sys.exit(1)
    if args.N < 1:
        print('N must be >= 1', file=sys.stderr)
        sys.exit(1)
    if args.K > args.N:
        print('K must be <= N', file=sys.stderr)
        sys.exit(1)

    return args


def get_files_in_trees(trees):
    for tree in trees:
        for (dirpath, dirnames, filenames) in \
            os.walk(tree, topdown=True, followlinks=True):
            for filename in filenames:
                yield os.path.join(dirpath, filename)


img_extensions = ['.' + ext.lower() for ext in
        ['jpg', 'jpeg', 'png', 'bmp']]

def is_image_file(filename):
    filename = filename.lower()
    for ext in filter(lambda e: filename.endswith(e), img_extensions):
        return True
    else:
        return False


if __name__ == '__main__':
    args = get_valid_args()

    random.seed()
    if random.randrange(args.N) < args.K:
        pass
    else:
        print('Not setting wallpaper (K={}, N={})'.format(args.K, args.N),
                file=sys.stderr)
        sys.exit(0)

    all_files = get_files_in_trees(args.trees)
    img_files = list(filter(is_image_file, all_files))
    if not img_files:
        print('No image files found in', args.trees, file=sys.stderr)
        sys.exit(0)

    img_file = os.path.abspath(random.choice(img_files))
    cmd = 'gconftool-2 --type string ' \
            '--set /desktop/gnome/background/picture_filename'.split(' ')
    cmd.append(img_file)
    exitcode = subprocess.call(cmd)

    if exitcode:
        print('gconftool-2 exited with code', exitcode, file=sys.stderr)
    else:
        print('background image set to', img_file)

    if args.style:
        cmd = 'gconftool-2 --type string ' \
                '--set /desktop/gnome/background/picture_options'.split(' ')
        cmd.append(args.style)
        exitcode = subprocess.call(cmd)
        if exitcode:
            print('gconftool-w exited with code', exitcode,
                    'while setting resizing style', file=sys.stderr)
        else:
            print('picture_options set to style', "'" + args.style + "'")

    if args.link:
        try:
            if os.path.lexists(args.link):
                os.remove(args.link)
            os.symlink(img_file, args.link)
            print('symlink', args.link, 'set to point to', img_file)
        except OSError as e:
            print(type(e).__name__, 'during symlink operations:', e,
                    file=sys.stderr)
