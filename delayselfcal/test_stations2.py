import casacore.tables as ct
import os
import matplotlib
matplotlib.use('Agg')
import numpy as np
from astropy.io import fits
import os.path
import matplotlib.pyplot as plt
from astropy.wcs import WCS

def findrms(mIn,maskSup=1e-7):
    """
    find the rms of an array, from Cycil Tasse/kMS
    """
    m=mIn[np.abs(mIn)>maskSup]
    rmsold=np.std(m)
    diff=1e-1
    cut=3.
    bins=np.arange(np.min(m),np.max(m),(np.max(m)-np.min(m))/30.)
    med=np.median(m)
    for i in range(10):
        ind=np.where(np.abs(m-med)<rmsold*cut)[0]
        rms=np.std(m[ind])
        if np.abs((rms-rmsold)/rmsold)<diff: break
        rmsold=rms
    return rms


def plotimage_astropy(fitsimagename, outplotname, mask=None, rmsnoiseimage=None):
    # image noise for plotting
    if rmsnoiseimage == None:
        hdulist = fits.open(fitsimagename)
    else:
        hdulist = fits.open(rmsnoiseimage)
    imagenoise = findrms(np.ndarray.flatten(hdulist[0].data))
    hdulist.close()

    # image noise info
    hdulist = fits.open(fitsimagename)
    imagenoiseinfo = findrms(np.ndarray.flatten(hdulist[0].data))
    hdulist.close()

    data = fits.getdata(fitsimagename)
    head = fits.getheader(fitsimagename)
    f = plt.figure()
    ax = f.add_subplot(111, projection=WCS(head), slices=('x', 'y', 0, 0))
    img = ax.imshow(data[0, 0, :, :], cmap='bone', vmax=16 * imagenoise, vmin=-6 * imagenoise)
    ax.set_title(fitsimagename + ' (noise = {} mJy/beam)'.format(round(imagenoiseinfo * 1e3, 3)))
    ax.grid(True)
    ax.set_xlabel('Right Ascension (J2000)')
    ax.set_ylabel('Declination (J2000)')
    cbar = plt.colorbar(img)
    cbar.set_label('Flux (Jy beam$^{-1}$')

    if mask is not None:
        maskdata = fits.getdata(mask)[0, 0, :, :]
        ax.contour(maskdata, colors='red', levels=[0.1 * imagenoise], filled=False, smooth=1, alpha=0.6,
                   linewidths=1)

    if os.path.isfile(outplotname + '.png'):
        os.system('rm -f ' + outplotname + '.png')
    plt.savefig(outplotname, dpi=450, format='png')
    return


def plotimage_aplpy(fitsimagename, outplotname, mask=None, rmsnoiseimage=None):
    import aplpy
    # image noise for plotting
    if rmsnoiseimage == None:
        hdulist = fits.open(fitsimagename)
    else:
        hdulist = fits.open(rmsnoiseimage)
    imagenoise = findrms(np.ndarray.flatten(hdulist[0].data))
    hdulist.close()

    # image noise info
    hdulist = fits.open(fitsimagename)
    imagenoiseinfo = findrms(np.ndarray.flatten(hdulist[0].data))
    hdulist.close()

    f = aplpy.FITSFigure(fitsimagename, slices=[0, 0])
    f.show_colorscale(vmax=16 * imagenoise, vmin=-6 * imagenoise, cmap='bone')
    f.set_title(fitsimagename + ' (noise = {} mJy/beam)'.format(round(imagenoiseinfo * 1e3, 3)))
    try:  # to work around an aplpy error
        f.add_beam()
        f.beam.set_frame(True)
        f.beam.set_color('white')
        f.beam.set_edgecolor('black')
        f.beam.set_linewidth(1.)
    except:
        pass

    f.add_grid()
    f.grid.set_color('white')
    f.grid.set_alpha(0.5)
    f.grid.set_linewidth(0.2)
    f.add_colorbar()
    f.colorbar.set_axis_label_text('Flux (Jy beam$^{-1}$)')
    if mask is not None:
        try:
            f.show_contour(mask, colors='red', levels=[0.1 * imagenoise], filled=False, smooth=1, alpha=0.6,
                           linewidths=1)
        except:
            pass
    if os.path.isfile(outplotname + '.png'):
        os.system('rm -f ' + outplotname + '.png')
    f.save(outplotname, dpi=120, format='png')
    return


def plotimage(fitsimagename,outplotname,mask=None,rmsnoiseimage=None):
  # This code tries astropy first, switches to aplpy afterwards.
  try:
      plotimage_astropy(fitsimagename,outplotname,mask,rmsnoiseimage)
  except:
      plotimage_aplpy(fitsimagename,outplotname,mask,rmsnoiseimage)

msin="L769393_120_168MHz_averaged.ms.avg"


t = ct.table(msin+'::ANTENNA')
stations = t.getcol("NAME")
t.close()

for station in stations:
    if station!='ST001':

        msout = "not_station_"+station+".ms"

        os.system("DPPP msin="+msin+" \
        steps=[filter] \
        filter.baseline=\'!"+station+"' \
        filter.remove='true' \
        msin.datacolumn=CORRECTED_DATA \
        msout.storagemanager=dysco \
        msout="+msout)

        os.system("wsclean -no-update-model-required "
                  "-minuv-l 1500.0 "
                  "-size 1600 1600 "
                  "-reorder "
                  "-weight briggs -1.5 "
                  "-clean-border 1 "
                  "-parallel-reordering 4 "
                  "-mgain 0.8 "
                  "-data-column DATA "
                  "-padding 1.4 "
                  "-join-channels "
                  "-channels-out 6 "
                  "-auto-mask 2.5 "
                  "-auto-threshold 0.5 "
                  "-fit-spectral-pol 3 "
                  "-pol i "
                  "-baseline-averaging 6.135923151542564 "
                  "-use-wgridder "
                  "-name not_station_"+station+" "
                "-scale 0.075arcsec "
                "-nmiter 12 "
                "-niter 15000 "+msout)

        plotimage('not_station_'+station+'-MFS-image.fits', 'not_'+station+'.png')


