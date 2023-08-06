from shapely import geometry
import numpy as np
import tables
from glob import glob
import csv
from argparse import ArgumentParser
from shapely import affinity
from astropy.coordinates import SkyCoord

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

def split_polygons_ds9(regionfile, extra_boundary=0.):
    """
    Split polygons in ds9
    :param regionfile: region file
    :param extra_boundary: adding extra boundary layer
    :return:
    """
    regionfile = open(regionfile, 'r')
    lines = regionfile.readlines()
    header = lines[0:4]
    polygons = lines[4:]
    for n, poly in enumerate(polygons):
        if extra_boundary>0:
            poly_file = open('poly_' + str(n)+'.reg', 'w')
        else:
            poly_file = open('poly_' + str(n) + '.reg', 'w')
        poly_file.writelines(header)
        polyp = [float(p) for p in poly.replace('polygon(', '').replace(')', '').replace('\n', '').split(',')]
        poly_geo = geometry.Polygon(tuple(zip(polyp[0::2], polyp[1::2])))
        if extra_boundary!=0.:
            poly_geo = poly_geo.buffer(extra_boundary, resolution=len(polyp[0::2]), join_style=2)
        poly = 'polygon'+str(tuple(item for sublist in poly_geo.exterior.coords[:] for item in sublist))
        poly_file.writelines(poly)
    regionfile.close()

def distance(c1, c2):
    c1 = SkyCoord(f'{c1[0]}deg', f'{c1[1]}deg', frame='icrs')
    c2 = SkyCoord(f'{c2[0]}deg', f'{c2[1]}deg', frame='icrs')
    return c1.separation(c2).value

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
    if poly_geo.contains(point_geo):
        c_x, c_y = poly_geo.centroid.x, poly_geo.centroid.y

        list_x = poly_geo.boundary.coords.xy[0]
        list_y = poly_geo.boundary.coords.xy[1]

        # max distance from center
        max_dist = 0
        for i in range(len(list_x)):
            dist = distance([c_x, c_y], [list_x[i], list_y[i]])
            if dist > max_dist:
                max_dist = dist
                max_point = [list_x[i], list_y[i]]

        # calculate averaging factor based on 2.5 by 2.5 degrees field size
        avg = max(int(2.5//(2*max(distance([c_x, c_y], [max_point[0], c_y]), distance([c_x, c_y], [c_x, max_point[1]])))), 1)

        print(c_x, c_y, max_point, avg)
        return poly_geo.contains(point_geo), poly_geo.area, [c_x, c_y], avg

    else:
        return False, None, None, None



if __name__ == "__main__":

    parser = ArgumentParser(description='Split facet file into smaller facets')
    parser.add_argument('--reg', help='region file', type=str, required=True)
    parser.add_argument('--h5', help='h5 file to write directions from', type=str, required=True)
    parser.add_argument('--extra_boundary', help='make polygons with extra boundaries', type=float, default=0.)
    args = parser.parse_args()

    reg = args.reg
    solutionfile = args.h5

    split_polygons_ds9(regionfile=reg, extra_boundary=args.extra_boundary)

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
    writer.writerow(['idx', 'dir_name', 'polygon_file', 'dir', 'poly_center', 'area', 'avg'])
    for n, dir in enumerate(dirs):
        for polygonregion_file in glob('poly_*.reg'):
            point_in_poly, poly_area, poly_center, avg = ds9_poly_info(dir, polygonregion_file)
            if point_in_poly:
                print(n, make_utf8(dirname[n]), polygonregion_file)
                writer.writerow([n,
                                 make_utf8(dirname[n]),
                                 polygonregion_file,
                                 '['+str(dir[0])+'deg'+','+str(dir[1])+'deg'+']',
                                 '['+str(round(poly_center[0], 5))+'deg'+','+str(round(poly_center[1], 5))+'deg'+']',
                                 poly_area,
                                 avg])

    f.close()

