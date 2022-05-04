import os
import argparse

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--to_path', type=str, help='path')
parser.add_argument('--input', type=str, help='input data')
parser.add_argument('--parallel', action='store_true', help='parallel')
parser.add_argument('--n', type=int, help='parallel')

args = parser.parse_args()

urls = open(args.input, 'r')

if not args.parallel:
    for url in urls.readlines():
        url = url.replace("\n", "")
        cmd = f'wget -ci {url} -P {args.to_path}'
        print(cmd)
        try:
            os.system(cmd)
        except:
            print('FAIL: '+cmd)
else:
    urls_list = [u.replace("\n", "") for u in urls.readlines()]
    cmd = f'wget -ci {urls_list[int(args.n)]} -P {args.to_path}'
    try:
        os.system(cmd)
    except:
        print('FAIL: '+cmd)