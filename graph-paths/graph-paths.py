#! /usr/bin/env python3

import argparse
from collections import OrderedDict
import json
import sys


sample_graph_info = [('a', 'b'), ('b', 'd'), ('a', 'c'), ('c', 'd')]

def parse_args():
    parser = argparse.ArgumentParser(
            description='Find all paths between two graph nodes')

    parser.add_argument('graph_file', help='''(path to) JSON file
            describing the graph in the following format: '''
            + json.dumps(sample_graph_info)
            + '''. It is a list of edges. An edge connecting nodes 'a' and 'b'
            is the list ["a", "b"]. The file must be encoded using UTF-8.''')
    parser.add_argument('source', help='The source node for the search')
    parser.add_argument('dest', help='The destination node for the search')
    parser.add_argument('--directed', action='store_true',
            help='The graph is directed.')

    return parser.parse_args()


def exit_with_msg(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


def check_graph(edge_list):
    '''Checks that what we've read from JSON is as expected, or exists.'''

    if type(edge_list) != list:
        exit_with_msg('Error: JSON file must contain a list')
    for edge in edge_list:
        if type(edge) != list or len(edge) != 2:
            exit_with_msg('Error: Each graph edge must be a list ' +
                    'connecting exactly 2 nodes')
        for node in edge:
            if type(node) != str:
                exit_with_msg('Error: each graph node must be a string')


def build_graph(edge_list, directed):
    '''
    Builds a graph (using adjacency lists) from the JSON list of edges.

    Returns a dictionary { node_name : {set_of_adjacent_nodes} }
    '''

    graph = {}
    for u, v in edge_list:
        # make sure both nodes exist as dictionary keys
        for x in (u, v):
            if x not in graph:
                graph[x] = set()

        graph[u].add(v)
        if not directed:
            graph[v].add(u)

    return graph


def dfs(graph, src, dest):
    '''Depth-first search graph from src to target, printing all paths.'''

    # For each node on the current path, we store an iterator for its
    # adjacency list: this allows us to continue searching when we backtrack.
    path = OrderedDict()
    path[src] = iter(graph[src])

    while path:
        frontier = next(reversed(path), None)
        if frontier == dest:
            print('-'.join(path.keys()))
            path.popitem()
            continue

        # search for the next node using the iterator
        it = path[frontier]
        x = next(it, None)
        while x and x in path:
            x = next(it, None)

        if x:
            path[x] = iter(graph[x])
        else:
            path.popitem()


if __name__ == '__main__':
    args = parse_args()

    with open(args.graph_file, 'r', encoding='utf-8') as f:
        edge_list = json.load(f)
    check_graph(edge_list)
    graph = build_graph(edge_list, args.directed)

    if args.source not in graph or args.dest not in graph:
        exit_with_msg('Source and Dest must be Graph Nodes')

    dfs(graph, args.source, args.dest)
