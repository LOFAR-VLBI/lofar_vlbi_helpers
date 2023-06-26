from shapely import geometry
import numpy as np
import tables
from glob import glob
import csv
from argparse import ArgumentParser

def make_utf8(inp):
    """
    Convert input to utf8 instead of bytes

    :param inp: string input
    """
    try:
        inp = inp.decode('utf8')
        return inp
    except (UnicodeDecodeError, AttributeError):
        return inp

def split_polygons_ds9(regionfile):
    """
    Split polygons in ds9
    :param regionfile: region file
    :return:
    """
    regionfile = open(regionfile, 'r')
    lines = regionfile.readlines()
    header = lines[0:4]
    polygons = lines[4:]
    for n, poly in enumerate(polygons):
        poly_file = open('poly_' + str(n) + '.reg', 'w')
        poly_file.writelines(header)
        poly_file.writelines([poly])
    regionfile.close()

def ds9_poly_info(point, poly_reg):
    """
    Is point in polygon region file

    :param point: list or tuple with 2D coordinate
    :param poly_reg: polygon region file
    :return: point in geo, polygon area
    """
    polyregion = open(poly_reg, 'r')
    lines = polyregion.readlines()
    poly = lines[4]
    polyregion.close()
    polyp = [float(p) for p in poly.replace('polygon(', '').replace(')', '').replace('\n', '').split(',')]
    poly_geo = geometry.Polygon(tuple(zip(polyp[0::2], polyp[1::2])))
    point_geo = geometry.Point(point)
    return poly_geo.contains(point_geo), poly_geo.area


if __name__ == "__main__":

    parser = ArgumentParser(description='Split facet file into smaller facets')
    parser.add_argument('--reg', help='region file', type=str, required=True)
    parser.add_argument('--h5', help='h5 file to write directions from', type=str, required=True)
    args = parser.parse_args()

    reg = 'facets.reg'
    solutionfile = "merged_L686962.h5"

    split_polygons_ds9(reg)

    H = tables.open_file(solutionfile)
    dirs = H.root.sol000.source[:]['dir']
    dirname = H.root.sol000.source[:]['name']
    H.close()

    #dangerous!
    if np.all(np.abs(dirs)<np.pi):
        dirs %= (2*np.pi)
        dirs *= 360/(2*np.pi)

    f = open('polygon_info.csv', 'w')
    writer = csv.writer(f)
    writer.writerow(['idx', 'dir_name', 'polygon_file', 'dir', 'area', 'avg'])
    for n, dir in enumerate(dirs):
        for polygonregion_file in glob('poly_*.reg'):
            point_in_poly, poly_area = ds9_poly_info(dir, polygonregion_file)
            if point_in_poly:
                print(n, make_utf8(dirname[n]), polygonregion_file)
                writer.writerow([n, make_utf8(dirname[n]), polygonregion_file,
                                 '['+str(dir[0])+'deg'+','+str(dir[1])+'deg'+']', poly_area,
                                 max(int(np.sqrt(2.5*2.5/poly_area))-1, 1)])
    f.close()

