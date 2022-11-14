import tables
import argparse
import sys
from numpy import sum, all

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Compare measurement sets')
    parser.add_argument('--h5_1', default='', help='solution file 1')
    parser.add_argument('--h5_2', default='', help='solution file 2')

    args = parser.parse_args()

    h5_1 = tables.open_file(args.h5_1)
    h5_2 = tables.open_file(args.h5_2)

    sols = list(h5_1.root._v_groups.keys())

    for sol in sols:
        print(sol)

        sol_1 = h5_1.root._f_get_child(sol)
        sol_2 = h5_2.root._f_get_child(sol)

        ss_1_list = list(sol_1._v_groups.keys())
        ss_2_list = list(sol_2._v_groups.keys())

        for s in ss_1_list:
            print(s)
            if s not in ss_2_list:
                sys.exit("ERROR: solset lists not equal!")

            st_1 = sol_1._f_get_child(s)
            st_2 = sol_2._f_get_child(s)

            st_1_list = list(st_1._v_children.keys())
            st_2_list = list(st_2._v_children.keys())

            for st in st_1_list:
                if st in ['val', 'weight', 'time', 'freq']:
                    if sum(st_1._f_get_child(st)[:]-st_2._f_get_child(st)[:])!=0:
                        print(st_1._f_get_child(st)[:])
                        print(st_2._f_get_child(st)[:])
                        sys.exit("ERROR: "+st+" not equal!")
                elif st in ['ant', 'pol', 'dir']:
                    if not all(st_1._f_get_child(st)[:]==st_2._f_get_child(st)[:]):
                        print(st_1._f_get_child(st)[:])
                        print(st_2._f_get_child(st)[:])
                        sys.exit("ERROR: "+st+" not equal!")

    h5_1.close()
    h5_2.close()

    print('CONGRATS! ' + args.h5_1 + ' and ' + args.h5_2 + ' are equal!')