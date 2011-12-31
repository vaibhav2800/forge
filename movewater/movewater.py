#! /usr/bin/env python3

from myutil import params, bf, gui
import sys

if __name__ == '__main__':
    if len(sys.argv) == 1:
        gui.start_gui()
    else:
        data = params.get_data()
        (sol, path_back) = bf.find_first_sol(data)
        if sol:
            print(len(path_back) - 1, "steps:")
            for x in reversed(path_back):
                print(x)
        else:
            print("Impossible")
