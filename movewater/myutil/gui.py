from tkinter import *
from . import params, bf

def start_gui():
    root = Tk()
    root.title("Move water")

    fountain_var = IntVar(value=1)
    Checkbutton(root, text="fountain available",
            variable=fountain_var).pack(anchor=W)

    waste_var = IntVar(value=1)
    Checkbutton(root, text="can waste water",
            variable=waste_var).pack(anchor=W)

    f = Frame(root)
    f.pack(anchor=W, fill=X)
    Label(f, text="Bowl sizes:").pack(side=LEFT)
    sizes_txt = Entry(f)
    sizes_txt.pack(fill=X, expand=True, side=LEFT)
    Label(f, text="(e.g. 5 3 8)").pack(side=LEFT)

    def init_chk_click():
        if init_var.get():
            init_txt.config(state=NORMAL)
        else:
            init_txt.config(state=DISABLED)

    f = Frame(root)
    f.pack(anchor=W, fill=X)
    init_var = IntVar()
    Checkbutton(f, text="initial contents:", variable=init_var,
            command=init_chk_click).pack(side=LEFT)
    init_txt = Entry(f, state=DISABLED)
    init_txt.pack(fill=X, expand=True, side=LEFT)
    Label(f, text="(e.g. 2 0 4)").pack()

    f = Frame(root)
    f.pack(anchor=W, fill=X)
    Label(f, text="Target:").pack(side=LEFT)
    target_txt = Entry(f)
    target_txt.pack(side=LEFT, expand=True, fill=X)
    target_txt.bind('<Return>', lambda event:solve())
    Label(f, text="(e.g. 4 or 4 0 4)").pack()

    def solve():
        out.delete(1.0, END)
        try:
            volumes = tuple(int(x) for x in sizes_txt.get().split())
            target = tuple(int(x) for x in target_txt.get().split())

            if init_var.get():
                init = tuple(int(x) for x in init_txt.get().split())
            else:
                init = tuple()
        except ValueError as e:
            out.insert(END, str(e))
            return

        try:
            target = params.check_args(volumes, init, target)
        except Exception as e:
            out.insert(END, 'Error: ' + str(e))
            return

        data = {}
        data['fountain'] = fountain_var.get()
        data['waste'] = waste_var.get()
        data['sizes'] = volumes
        data['init'] = init
        data['target'] = target

        (sol, path_back) = bf.find_first_sol(data)
        if sol:
            out.insert(END, str(len(path_back) - 1) + " steps:")
            for x in reversed(path_back):
                out.insert(END, '\n' + str(x))
        else:
            out.insert(END, "Impossible")

    f = Frame(root)
    f.pack(anchor=W)
    Button(f, text="Solve", command=solve).pack(side=LEFT)
    Button(f, text="Exit", command=root.quit).pack()

    # TEXT area
    f = Frame(root)
    f.pack(expand=True, fill=BOTH)

    out = Text(f, height=8, width=10, wrap=NONE)

    v_scroll = Scrollbar(f, command=out.yview)
    v_scroll.pack(side=RIGHT, fill=Y)
    h_scroll = Scrollbar(f, orient=HORIZONTAL, command=out.xview)
    h_scroll.pack(side=BOTTOM, fill=X)

    out.config(yscrollcommand=v_scroll.set, xscrollcommand=h_scroll.set)
    out.pack(expand=True, fill=BOTH)

    root.mainloop()
