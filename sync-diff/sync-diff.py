#! /usr/bin/env python3

import subprocess, shlex, tempfile

dirPairs = [
        ['/path/to/d1', '/mirror/of/d1'],
        ['/path/to/d2', '/mirror/of/d2'],
    ]

lsCmd = shlex.split('ls -AgGR --time-style="+%Y-%m-%d %H:%M:%S %z"')
grepCmd = shlex.split('grep -v -e "^drwxr-xr-x " -e "^total [0-9][0-9]*$"')

def write_tree_metadata(dirPath, outFile):
    lsProc = subprocess.Popen(lsCmd, stdout=subprocess.PIPE, cwd=dirPath)
    grepProc = subprocess.Popen(grepCmd, stdout=outFile, stdin=lsProc.stdout)
    lsCode, grepCode = lsProc.wait(), grepProc.wait()
    if lsCode:
        raise Exception("ls error code:", lsCode)
    elif grepCode:
        raise Exception("grep error code:", grepCode)
    outFile.flush()

if __name__ == '__main__':
    for (d1, d2) in dirPairs:
        print(d1, d2, sep='\t')
        with tempfile.NamedTemporaryFile(prefix='sync-diff-') as f1, \
                tempfile.NamedTemporaryFile(prefix='sync-diff-') as f2:
            write_tree_metadata(d1, f1)
            write_tree_metadata(d2, f2)
            with open('/dev/null', 'w') as dev_null:
                diffCmd = ['diff', '-q', f1.name, f2.name]
                if subprocess.call(diffCmd, stdout=dev_null):
                    meldCmd = ['meld', f1.name, f2.name]
                    subprocess.call(meldCmd, stdout=dev_null)
                    break
    else:
        print()
        print('All', len(dirPairs), 'dir pairs in sync')
        print('Archive anything else (e.g. repositories)')
