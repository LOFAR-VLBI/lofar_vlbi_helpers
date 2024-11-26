from astropy.io import fits
from glob import glob
import numpy as np
from past.utils import old_div
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches


# def rms(image_data):
#     """
#     from Cyril Tasse/kMS
#
#     :param image_data: image data array
#     :return: rms (noise measure)
#     """
#
#     maskSup = 1e-7
#     m = image_data[np.abs(image_data)>maskSup]
#     rmsold = np.std(m)
#     diff = 1e-1
#     cut = 3.
#     med = np.median(m)
#     for _ in range(10):
#         ind = np.where(np.abs(m - med) < rmsold*cut)[0]
#         rms = np.std(m[ind])
#         if np.abs(old_div((rms-rmsold), rmsold)) < diff: break
#         rmsold = rms
#     return rms
#
# refim = "1asec_image_10_12-MFS-image.fits"
# with fits.open(refim) as refhdu:
#     refdat = refhdu[0].data
#
# fitsims = glob("1asec_image_?_6-MFS-image.fits")
#
# for im in fitsims:
#     with fits.open(im) as hdu:
#         dat = hdu[0].data
#     print(im, rms(refdat-dat), rms(dat), np.max(refdat-dat))

bits = [2, 3, 4, 6, 8][::-1]

noise_1 = [8.617071e-05, 4.923825e-05, 4.4109605e-05, 4.315182e-05, 4.315085e-05][::-1]
ref_1 = [4.3144766e-05, 4.3144766e-05, 4.3144766e-05, 4.3144766e-05, 4.3144766e-05]

noise_2 = [6.765227e-05, 4.0519935e-05, 3.700075e-05, 3.636947e-05, 3.6387177e-05][::-1]
ref_2 = [3.6368925e-05, 3.6368925e-05, 3.6368925e-05, 3.6368925e-05, 3.6368925e-05]

noise_3 = [9.957854e-05, 5.457854e-05, 4.5098823e-05, 4.3169115e-05, 4.3097058e-05][::-1]
ref_3 = [4.3043197e-05,4.3043197e-05,4.3043197e-05,4.3043197e-05,4.3043197e-05]

noise_4 = [7.310028e-05, 4.157863e-05, 3.6579328e-05, 3.5641857e-05, 3.5609573e-05][::-1]
ref_4 = [3.551354e-05,3.551354e-05,3.551354e-05,3.551354e-05,3.551354e-05]

noise_5 = [124.67, 75.15, 68.38, 67.07, 67.01][::-1]
ref_5 = [66.57,66.57,66.57,66.57,66.57]

volume_1 = [61, 78, 95, 129, 164][::-1]
refvol_1 = [206, 206, 206, 206, 206]


vol_1 = np.array(volume_1)*100//np.array(refvol_1)

# Calculate percentages
noise_increase_1 = (np.array(noise_1) * 100) // np.array(ref_1) - 100
noise_increase_2 = (np.array(noise_2) * 100) // np.array(ref_2) - 100
noise_increase_3 = (np.array(noise_3) * 100) // np.array(ref_3) - 100
noise_increase_4 = (np.array(noise_4) * 100) // np.array(ref_4) - 100
noise_increase_5 = (np.array(noise_5) * 100) // np.array(ref_5) - 100


# Enhanced plot with text annotations and legend entry for "Volume compression"
fig, ax = plt.subplots(figsize=(8, 6))

# Plot the lines
line1, = ax.plot(bits, noise_increase_1, marker='o', linestyle='-', linewidth=2, label='0.3" high S/N', color='darkblue')
line2, = ax.plot(bits, noise_increase_2, marker='s', linestyle='--', linewidth=2, label='0.3" low S/N', color='darkred')
line3, = ax.plot(bits, noise_increase_3, marker='d', linestyle='-.', linewidth=2, label='1.2" high S/N', color='darkgreen')
line4, = ax.plot(bits, noise_increase_4, marker='^', linestyle=':', linewidth=2, label='1.2" low S/N', color='black')
# line5, = ax.plot(bits, noise_increase_5, marker='D', linestyle='-', linewidth=2, label='Wide-field 1.2" imaging dataset', color='purple')


for b in bits:
    plt.plot([b, b], [-10, 150], linestyle='dotted', color='gray')

# Customizations for primary x-axis
ax.set_xticks(bits)
ax.set_xticklabels(['8 bits', '6 bits', '4 bits', '3 bits', '2 bits'], fontsize=15)
ax.tick_params(axis='both', labelsize=15)
ax.set_xlabel('Compression level', fontsize=16)
ax.set_ylabel('RMS increase (%)', fontsize=16)

# Add secondary x-axis for the annotations
def secondary_x_ticks(bits):
    return [f'{v}%' for v in vol_1]

secax = ax.secondary_xaxis('top')
secax.set_xticks(bits)
secax.set_xticklabels(secondary_x_ticks(bits))
secax.set_xlabel('Compression size (%)', fontsize=16)
secax.tick_params(axis='x', labelsize=14)

# Legend
ax.legend(handles=[line1, line2, line3, line4], fontsize=16, loc='upper left', frameon=True, framealpha=0.9)

# Layout adjustment
ax.grid(visible=False)
ax.set_ylim(-5, 145)
plt.tight_layout()

# Flipping the x-axis
plt.gca().invert_xaxis()

# Save plot
plt.savefig('/home/jurjen/Documents/ELAIS/paperplots/noise_increase.png', dpi=150)
