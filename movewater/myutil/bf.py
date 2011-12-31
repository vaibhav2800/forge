from collections import deque

def find_first_sol(data):
    '''Find (first solution, [path, to, start]) using a BF traversal'''

    volumes = data['sizes']
    target = data['target']
    init = data['init']
    if not init:
        init = tuple([0 for i in range(len(volumes))])
    fountain = data['fountain']
    waste = data['waste']

    known = {init:None}

    if is_solution(init, target):
        return (init, get_path_back(init, known))

    pending = deque()
    pending.append(init)

    while pending:
        parent = pending.popleft()
        for child in get_children(parent, volumes, fountain, waste):
            if child in known:
                continue

            known[child] = parent
            pending.append(child)
            if is_solution(child, target):
                return (child, get_path_back(child, known))

    return (None, [])


def get_children(parent, volumes, fountain, waste):
    '''Returns all states immediately reachable from parent'''

    result = []
    for src_pos, src_val in enumerate(parent):
        if waste and src_val > 0:
            result.append(parent[:src_pos] + (0,) + parent[src_pos + 1:])

        if fountain and src_val < volumes[src_pos]:
            result.append(parent[:src_pos]
                    + (volumes[src_pos],) + parent[src_pos + 1:])

        if src_val > 0:
            for dest_pos, dest_val in enumerate(parent):
                if dest_pos == src_pos:
                    continue

                free = volumes[dest_pos] - dest_val;
                if free == 0:
                    continue

                amount = min(src_val, free)
                child = list(parent)
                child[src_pos] -= amount
                child[dest_pos] += amount
                result.append(tuple(child))

    return result

def is_solution(candidate, target):
    if type(target) == tuple:
        return candidate == target
    return target in candidate

def get_path_back(sol, parent_dict):
    '''List states back to initial (which has no mapping to its parent)'''
    path_back = [sol]
    crt = sol
    while parent_dict[crt]:
        crt = parent_dict[crt]
        path_back.append(crt)
    return path_back
