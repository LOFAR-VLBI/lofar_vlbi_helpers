#!/usr/bin/env python2

'''
Adapted version of LoMorph flux and size measurement routines, sped up to avoid use of pyregion, and incorporating cutout extraction and thresholding
Written by JHC; floodmask routine modified from BM's LoMorph
'''

from astropy.io import fits
from astropy.wcs import WCS
from astropy.table import Table
import astropy.units as u
from collections import defaultdict
import pyregion
from astropy.coordinates import SkyCoord
import numpy as np
from skimage.measure import label
from itertools import combinations_with_replacement
from scipy.spatial.distance import pdist
from shapely.geometry.polygon import LinearRing
from shapely.geometry import Polygon
from shapely.ops import cascaded_union
import pandas as pd
import matplotlib.path as Path
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import sys
import os

# import matplotlib
# matplotlib.use('Agg')

# from __future__ import print_function

# generate global dicts of component properties

fluxdict = {}
sizedict = {}
mindict = {}
padict = {}
coordsdict = defaultdict(list)


# DTHRES=0.1 # neighbour search in degrees

def flatten(f, ra, dec, x, y, size, hduid=0, channel=0, freqaxis=3, verbose=True):
    """
    Flatten a fits file so that it becomes a 2D image. Return new header and
    data
    This version also makes a sub-image of specified size.
    """

    # flag=0
    print('Input ra, dec are ', ra, dec)
    naxis = f[hduid].header['NAXIS']
    if naxis < 2:
        raise RuntimeError('Can\'t make map from this')

    if verbose:
        print('Input image shape is', f[hduid].data.shape)
    ds = f[hduid].data.shape[-2:]
    by, bx = ds
    if size is None:
        xmin = 0
        ymin = 0
        xmax = bx
        ymax = by
    else:
        xmin = int(x - size)
        if xmin < 0:
            xmin = 0
        xmax = int(x + size)
        if xmax > bx:
            xmax = bx
        ymin = int(y - size)
        if ymin < 0:
            ymin = 0
        ymax = int(y + size)
        if ymax > by:
            ymax = by

    if ymax <= ymin or xmax <= xmin:
        # this can only happen if the required position is not on the map
        print(xmin, xmax, ymin, ymax)
        # print 'Failed to make subimage!'
        # flag=1
        raise RuntimeError('Failed to make subimage!')

    w = WCS(f[hduid].header)
    wn = WCS(naxis=2)

    wn.wcs.crpix[0] = w.wcs.crpix[0] - xmin
    wn.wcs.crpix[1] = w.wcs.crpix[1] - ymin
    wn.wcs.cdelt = w.wcs.cdelt[0:2]
    '''
    try:
        wn.wcs.pc=w.wcs.pc[0:2,0:2]
    except AttributeError:
        pass # pc is not present
    try:
        wn.wcs.cd=w.wcs.cd[0:2,0:2]
    except AttributeError:
        pass # cd is not present
    '''
    wn.wcs.crval = w.wcs.crval[0:2]
    wn.wcs.ctype[0] = w.wcs.ctype[0]
    wn.wcs.ctype[1] = w.wcs.ctype[1]

    header = wn.to_header()
    header["NAXIS"] = 2

    slice = []
    for i in range(naxis, 0, -1):
        if i == 1:
            slice.append(np.s_[xmin:xmax])
        elif i == 2:
            slice.append(np.s_[ymin:ymax])
        elif i == freqaxis:
            slice.append(channel)
        else:
            slice.append(0)
    if verbose:
        print(slice)

    hdu = fits.PrimaryHDU(f[hduid].data[slice], header)
    copy = ('EQUINOX', 'EPOCH', 'BMAJ', 'BMIN', 'BPA')
    for k in copy:
        r = f[hduid].header.get(k)
        if r:
            hdu.header[k] = r
    if 'TAN' in hdu.header['CTYPE1']:
        hdu.header['LATPOLE'] = f[hduid].header['CRVAL2']
    hdulist = fits.HDUList([hdu])
    return hdulist


def extract_subim(filename, ra, dec, size, hduid=0, verbose=True):
    """Extract a sub-image and return an HDU.
    filename: the input FITS file
    ra, dec: the position in degrees
    size: the half-size in degrees
    hduid: the element of the original HDU to use (default 0)
    verbose: print diagnostics (default True)
    """
    if isinstance(filename, fits.hdu.hdulist.HDUList):
        orighdu = filename
    else:
        if verbose:
            print('Opening', filename)
        orighdu = fits.open(filename)
    if 'CDELT2' in orighdu[hduid].header:
        delt = orighdu[hduid].header['CDELT2']
    else:
        # assuming no rotation here
        delt = orighdu[hduid].header['CD2_2']

    print('size and delt are ', size, delt)
    print(size, delt)
    psize = int(size / delt)

    ndims = orighdu[hduid].header['NAXIS']

    # hack for Mightee mosaic
    if 'CDELT4' in orighdu[hduid].header:
        ndims = 4
    pvect = np.zeros((1, ndims))
    lwcs = WCS(orighdu[hduid].header)
    pvect[0][0] = ra
    pvect[0][1] = dec
    imc = lwcs.wcs_world2pix(pvect, 0)
    x = imc[0][0]
    y = imc[0][1]
    flag = 0
    if verbose:
        print('Extracting sub-image')
    try:
        hdu = flatten(orighdu, ra, dec, x, y, psize, hduid=hduid, verbose=verbose)
    except:
        flag = 1
        hdu = None
    '''
    del(hdu[hduid].header['PC1_1'])
    del(hdu[hduid].header['PC2_2'])
    '''
    if flag == 0:
        hdu[hduid].header['CDELT2'] = delt
        hdu[hduid].header['CDELT1'] = -delt
    return hdu, flag


def find_noise(a):
    b = a.flatten()
    for i in range(10):
        m = np.nanmean(b)
        s = np.nanstd(b)
        b = b[b < (m + 5.0 * s)]
    return m, s


def find_noise_area(hdu, ra, dec, size, channel=0, true_max=False, debug=False):
    # ra, dec, size in degrees
    size /= 1.5
    if len(hdu[0].data.shape) == 2:
        cube = False
        ysize, xsize = hdu[0].data.shape
    else:
        channels, ysize, xsize = hdu[0].data.shape
        cube = True
    w = WCS(hdu[0].header)
    ras = [ra - size, ra - size, ra + size, ra + size]
    decs = [dec - size, dec + size, dec - size, dec + size]
    xv = []
    yv = []
    for r, d in zip(ras, decs):
        if cube:
            x, y, c = w.wcs_world2pix(r, d, 0, 0)
        else:
            x, y = w.wcs_world2pix(r, d, 0)
        xv.append(x)
        yv.append(y)
    if debug: print(xv, yv)
    xmin = int(min(xv))
    if xmin < 0: xmin = 0
    xmax = int(max(xv))
    if xmax >= xsize: xmax = xsize - 1
    ymin = int(min(yv))
    if ymin < 0: ymin = 0
    ymax = int(max(yv))
    if ymax >= ysize: ymax = ysize - 1
    if debug: print(xmin, xmax, ymin, ymax)
    if cube:
        subim = hdu[0].data[channel, ymin:ymax, xmin:xmax]
    else:
        subim = hdu[0].data[ymin:ymax, xmin:xmax]
    if debug: subim.shape
    mean, noise = find_noise(subim)
    if true_max:
        vmax = np.nanmax(subim)
    else:
        for i in range(5, 0, -1):
            vmax = np.nanmedian(subim[subim > (mean + i * noise)])
            if not (np.isnan(vmax)):
                break
    return mean, noise, vmax


#############################################

# Flood-filling and masking function (uses scikit image label)
def FloodMaskBoth(source_name, cinc, cexc, hdu, rmsthres):
    flux_array = hdu[0].data

    # add rms thresholding step

    flux_array[flux_array < rmsthres] = np.nan
    mtest = np.nanmax(flux_array)
    print("Thresholding image at " + str(rmsthres))
    print("Floodmask: max val of thresholded array is: " + str(mtest))

    flooded_array = flux_array.copy()  # equivalent to thresholded npy arrays

    # excludeComp = 0

    sizey, sizex = flux_array.shape

    # make inclusion mask and exclusion mask

    exclude_mask = np.zeros((sizey, sizex), dtype=int)
    include_mask = np.zeros((sizey, sizex), dtype=int)
    # Define auxiliary array filled with 1, which we will use to create the masks, and auxiliary data array to fill in the ellipses

    one_mask = 1 * np.isfinite(np.zeros((sizey, sizex)))

    # In the auxiliary data array, turn to an arbitrary non-zero value the pixels inside the ellipse regions that correspond to the source

    w = WCS(hdu[0].header)

    mask = np.copy(include_mask)
    for src in cinc:
        sname = src['Component_Name']
        scoords = coordsdict.get(sname)
        sra = scoords[0]
        sdec = scoords[1]
        sflux = fluxdict.get(sname)
        smaj = sizedict.get(sname)
        smin = mindict.get(sname)
        sang = padict.get(sname)

        (xp, yp) = w.wcs_world2pix(sra, sdec, 1)
        cdelt = hdu[0].header['CDELT2']
        majpix = 2.0 * (smaj) / cdelt  # assumes component maj, min in deg
        minpix = 2.0 * (smin) / cdelt  # ditto
        # print "maj and min in pix are: "+str(majpix)+" and "+str(minpix)
        # Set component to 1s in existing exclusion mask
        nmask = AddMaskEllipse(mask, xp, yp, majpix, minpix, sang + 90.0)  # unsure about angle!
        # nmask=AddMaskEllipse(mask,xp,yp,majpix,minpix,sang)
        mask = nmask
        # mask=MaskEllipse(one_mask,xp,yp,majpix/2.0,minpix/2.0,sang+90.0)
        mtest = np.nanmax(nmask)

    nmasked = np.count_nonzero(nmask == 1)
    print("Floodmask: added included regions")
    print("Floodmask: number of non-zero pixels in region mask is " + str(nmasked))

    flux_array[nmask >= 1] = 0.02

    # flux_array should now have all included pixels set to non-int value, as well as other pix above the rms threshold set to their original non-nan values

    # now make separate mask identifying exclusion regions
    i = 0
    for row in cexc:
        source2 = row['Component_Name']
        ccoords = coordsdict.get(source2)
        comp_ra = ccoords[0]
        comp_dec = ccoords[1]
        comp_flux = fluxdict.get(source2)
        comp_maj = sizedict.get(source2)
        comp_min = mindict.get(source2)
        comp_pa = padict.get(source2)

        # w=WCS(hdu[0].header)
        # sc=SkyCoord(ra*u.deg,dec*u.deg,frame='icrs')
        (xp, yp) = w.wcs_world2pix(comp_ra, comp_dec, 1)
        cdelt = hdu[0].header['CDELT2']
        majpix = 2.0 * (comp_maj) / cdelt  # assumed comp maj,min in deg
        minpix = 2.0 * (comp_min) / cdelt
        # print "Adding component "+str(i)+"="+str(source2)+" to exclusion mask for source: "+str(source_name)
        # Set component to 1s in existing exclusion mask
        omask = AddMaskEllipse(exclude_mask, xp, yp, majpix, minpix, comp_pa + 90.0)  # unsure about angle!
        # omask=AddMaskEllipse(exclude_mask,xp,yp,majpix,minpix,comp_pa)
        exclude_mask = omask

        i = i + 1
    exclude_mask[exclude_mask > 1] = 1
    nmask[nmask > 1] = 1
    # exclude_mask should now contain all ellipses
    maxv = np.nanmax(exclude_mask)
    minv = np.nanmin(exclude_mask)
    # print("Floodmask: max of newmask is "+str(maxv)+" min of new mask is "+str(minv))
    mtest = np.count_nonzero(exclude_mask)
    print("Floodmask: number of non-zero pix in exclusion mask is " + str(mtest))
    print("Floodmask: exclude_mask complete")
    # Masking out excluded components
    exclude_overlap = exclude_mask + one_mask
    flux_array[exclude_overlap == 2] = np.nan

    # mtest=np.nanmax(flux_array)
    # Transform the data array into boolean, then binary values
    data_bin = 1 * (np.isfinite(flux_array))
    mtest = np.nanmax(data_bin)
    ntest = np.count_nonzero(data_bin)
    print("Floodmask: max of data_bin is: " + str(mtest))
    print("Floodmask: number of non-zero pix in data_bin is: " + str(ntest))
    # Label the data array: this method will assign a numerical label to every island of "1" in our binary data array; we want 8-style connectivity
    data_label = label(data_bin, connectivity=2)
    # Multiply the label array by the source regions array (post-masking of extraneous sources). This allows us to identify which labels correspond to the clusters of pixels belonging to the source
    mtest = np.nanmax(data_label)
    # print("Floodmask: max of data_label is: "+str(mtest))
    # print("Data label and mask shapes max and min")
    # print data_label.shape,mask.shape,np.nanmax(data_label),np.nanmin(data_label),np.nanmax(mask),np.nanmin(mask)
    include_overlap = data_label * nmask
    nmasked = np.count_nonzero(include_overlap > 0)
    # print("Floodmask: number of non-zero pixels in masked label array is "+str(nmasked))
    if np.max(include_overlap) == 0:
        print("No overlap between labelled regions and initial source!")

    # Get the list of label values, excluding zero
    multi_labels = np.unique(include_overlap[np.nonzero(include_overlap)])

    print("Floodmask: multi_labels is " + str(len(multi_labels)))
    # Initialise the cumulative mask
    multi_mask = np.zeros((sizey, sizex))
    # Main loop
    for i in range(0, len(multi_labels)):
        # Because of how masked arrays work, we need to explicitly set to zero the areas of the array we want masked out... we need a temporary masked array for the intermediate step
        temp_mask = (np.ma.masked_where(data_label != multi_labels[i], one_mask))
        temp_mask[temp_mask != 1] = 0
        # As we have used a 1/0 matrix as a basis, iteratively adding the island masks together will give us the full mask we need
        multi_mask = (multi_mask + temp_mask)
    # The output mask will only contain "1" in the areas corresponding to the islands of interest
    flooded_mask = multi_mask
    mtest = np.nanmax(flooded_mask)
    ntest = np.count_nonzero(flooded_mask)

    print("Floodmask: number of non-zero pix in output array is: " + str(ntest))

    flooded_array[flooded_mask == 0] = np.nan
    # for the purposes of this code we want to return the flooded mask and the flood-filled flux array
    palette = plt.cm.viridis
    palette.set_bad('k', 0.0)
    plt.rcParams['figure.figsize'] = (10.67, 8.0)
    A = np.ma.array(flooded_array, mask=np.isnan(flooded_array))
    y, x = np.mgrid[slice((0), (sizey), 1),
    slice((0), (sizex), 1)]
    plt.pcolor(x, y, A, cmap=palette, vmin=np.nanmin(A), vmax=np.nanmax(A))
    plt.axis([x.min(), x.max(), y.min(), y.max()])
    plt.savefig('images/' + source_name + '_farray.png')
    plt.clf()
    '''
    '''
    palette = plt.cm.viridis
    palette.set_bad('k', 0.0)
    plt.rcParams['figure.figsize'] = (10.67, 8.0)
    # A=np.ma.array(flooded_array,mask=np.isnan())
    y, x = np.mgrid[slice((0), (sizey), 1),
    slice((0), (sizex), 1)]
    plt.pcolor(x, y, nmask, cmap=palette, vmin=0, vmax=np.nanmax(nmask))
    plt.axis([x.min(), x.max(), y.min(), y.max()])
    plt.savefig('images/' + source_name + '_nmask.png')
    plt.clf()

    palette = plt.cm.viridis
    palette.set_bad('k', 0.0)
    plt.rcParams['figure.figsize'] = (10.67, 8.0)
    # A=np.ma.array(flooded_array,mask=np.isnan())
    y, x = np.mgrid[slice((0), (sizey), 1),
    slice((0), (sizex), 1)]
    plt.pcolor(x, y, exclude_mask, cmap=palette, vmin=0, vmax=np.nanmax(exclude_mask))
    plt.axis([x.min(), x.max(), y.min(), y.max()])
    plt.savefig('images/' + source_name + '_emask.png')
    plt.clf()

    palette = plt.cm.viridis
    palette.set_bad('k', 0.0)
    plt.rcParams['figure.figsize'] = (10.67, 8.0)
    # A=np.ma.array(flooded_array,mask=np.isnan())
    y, x = np.mgrid[slice((0), (sizey), 1),
    slice((0), (sizex), 1)]
    plt.pcolor(x, y, include_overlap, cmap=palette, vmin=0, vmax=np.nanmax(include_overlap))
    plt.axis([x.min(), x.max(), y.min(), y.max()])
    plt.savefig('images/' + source_name + '_incol.png')
    plt.clf()

    palette = plt.cm.viridis
    palette.set_bad('k', 0.0)
    plt.rcParams['figure.figsize'] = (10.67, 8.0)
    # A=np.ma.array(flooded_array,mask=np.isnan())
    y, x = np.mgrid[slice((0), (sizey), 1),
    slice((0), (sizex), 1)]
    plt.pcolor(x, y, data_label, cmap=palette, vmin=0, vmax=np.nanmax(data_label))
    plt.axis([x.min(), x.max(), y.min(), y.max()])
    plt.savefig('images/' + source_name + '_labels.png')
    plt.clf()
    return (flooded_mask, flooded_array)


#####

def pointInEllipse(x, y, xp, yp, d, D, angle):
    # tests if a point[xp,yp] is within
    # boundaries defined by the ellipse
    # of center[x,y], diameter d D, and tilted at angle

    cosa = np.cos(angle * np.pi / 180.0)
    sina = np.sin(angle * np.pi / 180.0)
    dd = (d / 2.0) * (d / 2.0)
    DD = (D / 2.0) * (D / 2.0)

    a = (cosa * (xp - x) + sina * (yp - y)) ** 2.0
    b = (sina * (xp - x) - cosa * (yp - y)) ** 2.0
    ellipse = (a / dd) + (b / DD)

    if ellipse <= 1:
        return True
    else:
        return False


#####

def MaskEllipse(narray, x, y, a, b, angle):
    # takes an array and turns it into a mask that excludes everything not in ellipse with 1s inside ellipse
    yy = narray.shape[0]
    xx = narray.shape[1]
    cosa = np.cos(angle * np.pi / 180.0)
    sina = np.sin(angle * np.pi / 180.0)
    dd = (a / 2.0) * (b / 2.0)
    DD = (b / 2.0) * (b / 2.0)
    # print("MaskEllipse - array has size :",xx,yy)
    xvals = np.arange(0, xx)
    yvals = np.arange(0, yy)
    # print("Length of xvals and yvals:",len(xvals),len(yvals))
    xarr, yarr = np.meshgrid(xvals, yvals)
    apar = (cosa * (x - xarr) + sina * (y - yarr)) ** 2.0
    bpar = (sina * (x - xarr) - cosa * (y - yarr)) ** 2.0
    ellipse = (apar / dd) + (bpar / DD)
    tomask = np.where(ellipse <= 1, 1, 0)
    return tomask


#####
def AddMaskEllipse(inmask, x, y, a, b, angle):
    # takes an array and adds +1 to every point inside provided ellipse
    narray = inmask
    ''' convert ellipse pars to pix
    w=WCS(hdu[0].header)
    sc=SkyCoord(ra*u.deg,dec*u.deg,frame='icrs')
    (xp,yp)=w.world_to_pixel(sc)
    '''
    yy = narray.shape[0]
    xx = narray.shape[1]
    cosa = np.cos(angle * np.pi / 180.0)
    sina = np.sin(angle * np.pi / 180.0)
    dd = (a / 2.0) * (b / 2.0)
    DD = (b / 2.0) * (b / 2.0)
    xvals = np.arange(0, xx)
    yvals = np.arange(0, yy)
    xarr, yarr = np.meshgrid(xvals, yvals)
    # print("Shapes of meshgrid input and output and apar,bpar:")
    # print xvals.shape,yvals.shape
    # print xarr.shape,yarr.shape
    apar = (cosa * (x - xarr) + sina * (y - yarr)) ** 2.0
    bpar = (sina * (x - xarr) - cosa * (y - yarr)) ** 2.0
    # print apar.shape,bpar.shape
    ellipse = (apar / dd) + (bpar / DD)
    # print("Ellipse shape is")
    # print ellipse.shape
    # print "AddMaskEllipse maj and min are :",a,b
    tomask = np.where(ellipse <= 1, 1, 0)
    spix = np.count_nonzero(tomask)
    # print "AddMaskEllipse area in pix is :",spix
    newmask = narray + tomask
    # maskarr=np.where(newmask>0,1,0) # retain previous masks but set all to 1
    maxv = np.nanmax(newmask)
    minv = np.nanmin(newmask)
    # print("AddMaskEllipse: max of newmask is "+str(maxv)+" min of new mask is "+str(minv))
    return newmask


#####

# Maxdist function

def maxdist(a, x, y):
    # For a given set of x, y values find the maximum distance of any non-zero point

    ny, nx = a.shape
    xa = np.linspace(0, nx - 1, nx)
    ya = np.linspace(0, ny - 1, ny)
    xv, yv = np.meshgrid(xa, ya)
    dx = xv - x
    dy = yv - y
    d2dx = dx * dx
    d2dy = dy * dy
    d2dxdy = d2dx + d2dy
    ddxdy = np.sqrt(d2dxdy)
    dmax = np.max(ddxdy[~np.isnan(a)])
    return dmax


#####

def length(a):
    sizey, sizex = a.shape
    ddd = np.zeros_like(a)
    for x in range(sizex):
        for y in range(sizey):
            if not np.isnan(a[y, x]):
                ddd[y, x] = maxdist(a, x, y)

    return np.max(ddd)


#####

# def length2(a):
#     # this assumes square image, but we've set it up that way
#     ny, nx = a.shape
#     xa = np.linspace(0, nx - 1, nx)
#     # ya = np.linspace(0,ny-1,ny)
#
#     pairs = [(comb) for comb in combinations_with_replacement(xa, 2)]
#
#     print("lengths of pairs: ", len(pairs), len(newpairs))
#     dists = pdist(newpairs, 'Euclidean')
#     return np.nanmax(dists)


#####

def getfluxsize(data, fthres):
    # sum non-zero pixels

    flux = np.nansum(data)

    # get length
    if (flux > fthres):
        siz = length(data)
    else:
        siz = np.nan
    # siz=1.0
    return (flux, siz)


#####
def write_fits_out(col_order, data_list, outfile):
    outpd = pd.DataFrame(data_list)[col_order]
    fitst = Table.from_pandas(outpd)
    fitst.write(outfile, overwrite=True)


#####
def dfilt(cat, ra, dec, thres):
    outcat = cat[(np.abs(cat['RA'] - ra) * np.cos(dec * np.pi / 180.0) < thres) & (np.abs(cat['DEC'] - dec) < thres)]
    return outcat


#####

# MAIN

# Read in catalogues

incat = Table.read(sys.argv[1])
# incat.rename_column('RA_1', 'RA')
# incat.rename_column('DEC_1', 'DEC')
# incat.rename_column('Source_Name_1', 'Source_Name')
compcat = Table.read(sys.argv[2])
imfile = sys.argv[3]

print("Lengths of cats are ", len(incat), len(compcat))

outcat = []

for asrc in compcat:
    sourcename = asrc['Component_Name']
    newname = sourcename.rstrip()
    sourcera = float(asrc['RA'])
    sourcedec = float(asrc['DEC'])
    flux = float(asrc['Total_flux'])
    majsize = float(asrc['Maj'])
    minsize = float(asrc['Min'])
    posang = float(asrc['PA'])

    coordsdict.update({newname: (sourcera, sourcedec)})
    fluxdict.update({newname: flux})
    sizedict.update({newname: majsize})
    mindict.update({newname: minsize})
    padict.update({newname: posang})

# Loop through rows, making cutout for each source, generating floodmask and then measuring size and flux

nsrc = len(incat)

os.system('mkdir -p cutouts')

i = 0
for src in incat:
    ra = src['RA']
    dec = src['DEC']
    # Hopefully for DR2 can get mosaic from cat?
    # mos=str(src['Mosaic_ID'])
    # img=mos.rstrip()
    img = imfile
    maj = src['Maj']
    sname = src['Source_Name']
    name = sname.rstrip()

    # rms=src['Isl_rms'] # deep fields version - check units of im and cat
    lgz = src['LGZ_Size']
    influx = src['Total_flux']
    peak = src['Peak_flux']

    # get initial masking threshold

    # rthres=4.0*rms

    # Would be useful to have an existing LGZ_Size to assess size for cutout
    # minSize=0.0045 # units?
    if np.isnan(lgz):
        srcSize = maj
    else:
        srcSize = lgz / 3600.0
    if srcSize < 0.0045:
        srcSize = 0.0045

    try:
        srcSize = float(srcSize)
        if not srcSize==srcSize:
            continue
    except:
        continue

    size = 2.0 * srcSize  # cutout size

    # extract fits cutout as hdu obj
    cutout, ff = extract_subim(img, ra, dec, size)

    if ff == 0:
        cutout.writeto('cutouts/' + name + '.fits', overwrite=True)

    if ff == 0:

        rms = find_noise_area(cutout, ra, dec, 2.0 * size)[1]
        print("rms is ", rms)
        # Original setting
        # rthres=max(4.0*rms,peak/50.0)
        rthres = max(5.0 * rms, peak / 50.0)
        bmaj = cutout[0].header['BMAJ']
        bmin = cutout[0].header['BMIN']
        pdel = cutout[0].header['CDELT1']
        pdel = np.abs(pdel)
        bmaj /= pdel
        bmin /= pdel
        gfac = 2.0 * np.sqrt(2.0 * np.log(2.0))
        beamarea = 2.0 * np.pi * bmaj * bmin / (gfac * gfac)  # beam area in pix
        # print "Beam area in pix is ",beamarea

        # Generate mask by first masking in source components then excluding others
        # print "Extracting cats for source ",name
        # print "Size is ",size
        mask = compcat['Parent_Source'] == name
        mask2 = compcat['Parent_Source'] != name
        catinc = compcat[mask]
        dcatexc = compcat[mask2]
        # print "Lengths of included and excluded comps are:",len(catinc),len(dcatexc)
        catexc = dfilt(dcatexc, ra, dec, 1.5 * size)
        # print "Lengths of included and excluded comps are:",len(catinc),len(catexc)

        floodmask, floodim = FloodMaskBoth(name, catinc, catexc, cutout, rthres)
        floodmask2 = np.where(np.ma.getmask(floodmask), np.nan, floodmask)
        fits.writeto('cutouts/' + name + '_floodmask.fits', overwrite=True, data=floodmask2, header=cutout[0].header)
        fits.writeto('cutouts/' + name + '_floodim.fits', overwrite=True, data=floodim, header=cutout[0].header)

        # Calculate flux and size
        # fl,sz=getfluxsize(floodim,influx/20.0)
        fl, sz = getfluxsize(floodim, rthres)

        totflux = fl / beamarea
        totsize = (sz * pdel) * 3600.0

        outcat.append({'Source_Name': name, 'RA': ra, 'DEC': dec, 'Total_flux_LoTSS': influx, 'New_flux': totflux,
                       'Maj_LoTSS': maj * 3600.0, 'LGZ_Size_LoTSS': lgz, 'New_size': totsize})

    else:
        print('Cutout failed for ' + str(name))

    print("Processing source ", i, "/", nsrc)
    i = i + 1

write_fits_out(['Source_Name', 'RA', 'DEC', 'Total_flux_LoTSS', 'New_flux', 'Maj_LoTSS', 'LGZ_Size_LoTSS', 'New_size'],
               outcat, 'LM-size-flux.fits')