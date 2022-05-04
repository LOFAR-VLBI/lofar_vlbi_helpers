import os
import argparse

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--to_path', type=str, help='path')
parser.add_argument('--input', type=str, help='input data')

args = parser.parse_args()

urls = open(args.input, 'r')
for url in urls.readlines():
    cmd = f'wget {url} -P {args.to_path}'
    print(cmd)
    try:
        os.system(cmd)
    except:
        print('FAIL: '+cmd)

