from optparse import OptionParser
import sys

# init module: create parser

parser = OptionParser(usage="%prog [options] V1,V2,..,Vn x[,x2,..,xn]\n"
        "running without arguments starts GUI\n\n"
        "V1,V2,..,Vn are volumes of the bowls (e.g. 8,3,5)\n"
        "x[,x2,..,xn] is the desired outcome, given as:\n"
        "  1) x litres in any bowl (e.g. 4) or\n"
        "  2) final state x,x2,..,xn for all bowls (e.g. 4,0,4)")
parser.add_option("--no-fountain", action="store_true",
        dest="no_fountain", help="make water source unavailable")
parser.add_option("--no-waste", action="store_true",
        dest="no_waste", help="forbid throwing away water")
parser.add_option("-i", "--init", metavar="I1,I2,..,In",
        help="Initial amount of water in V1,V2,..,Vn")


def get_data():
    '''Dictionary obtained from sys.argv.

    {fountain:bool, waste:bool, sizes:(8, 3, 5), init:tuple() or (8, 0, 2),
    target: 4 or (4, 0, 4)}
    '''

    (options, pos_args) = parser.parse_args()

    if len(pos_args) != 2:
        parser.print_help()
        print("\nERROR: 2 args required (V1,..,Vn x[,..,xn]) but",
                len(pos_args), "supplied")
        sys.exit(1)

    # convert "a,b,c" args to (int(a), .. , int(c))
    try:
        v_str, x_str = pos_args

        volumes = tuple(int(v) for v in v_str.split(","))
        target = tuple(int(x) for x in x_str.split(","))

        if options.init:
            init = tuple(int(i) for i in options.init.split(","))
        else:
            init = tuple()
    except ValueError as e:
        print('Error:', e)
        sys.exit(1)

    try:
        target = check_args(volumes, init, target)
    except Exception as e:
        print('Error', e)
        sys.exit(1)

    # make result dictionary
    result = {}
    result['sizes'] = volumes
    result['target'] = target
    result['fountain'] = not options.no_fountain
    result['waste'] = not options.no_waste
    result['init'] = init

    return result

def check_args(volumes, init, target):
    '''Checks arguments and returns target (as single value or tuple).
    
    If target contains a single item, the item is returned.
    Otherwise the target tuple is returned unchanged.
    
    Exceptions thrown:
        Exception -- if bad arguments
    '''
    # volumes
    if len(volumes) == 0:
        raise Exception('no bowl sizes specified')
    for v in volumes:
        if v <= 0:
            raise Exception(str(v) + ' not a valid volume; must be > 0')

    # init
    if len(init) > 0 and len(init) != len(volumes):
        raise Exception(str(len(volumes)) + ' bowls with '
                + str(len(init)) + ' init values')

    for pos,val in enumerate(init):
        if val < 0:
            raise Exception(str(val) + ' not a valid init; must be >= 0')
        if val > volumes[pos]:
            raise Exception(str(val) + ' not a valid init; must be <= '
                    + str(volumes[pos]))

    # target
    if len(target) == 0:
        raise Exception('no target given')
    if len(target) > 1 and len(target) != len(volumes):
        raise Exception(str(len(volumes)) + ' bowls with '
                + str(len(target)) + ' targets')

    for t in target:
        if t < 0:
            raise Exception(str(t) + ' not valid in target; must be >= 0')

    if len(target) == 1:
        target = target[0]
        if target > max(volumes):
            raise Exception(str(target) + ' not a valid target; must be <= '
                    + str(max(volumes)))
    else:
        for pos, val in enumerate(target):
            if val > volumes[pos]:
                raise Exception(str(val) + ' not a valid target; must be <= '
                        + str(volumes[pos]))

    return target
