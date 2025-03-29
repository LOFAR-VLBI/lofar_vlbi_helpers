from scipy.stats import circstd
import tables
import numpy as np
import matplotlib.pyplot as plt


def get_indices_int_stations(calsol):
    with tables.open_file(calsol) as H:
        ants = H.root.calibrator.polalign.ant[:]
        ants_indices = [(idx, a.decode('utf8')) for idx, a in enumerate(ants)
                        if 'CS' not in a.decode('utf8') and 'RS' not in a.decode('utf8')]
    return np.array(ants_indices)

def get_polalign_station(calsol):
    stats = get_indices_int_stations(calsol)
    with tables.open_file(calsol) as H:
        polalign = H.root.calibrator.polalign.val[..., 1]
        freqs = H.root.calibrator.polalign.freq[:]
        freqs = freqs[(freqs>120*1e6) & (freqs<168*1e6)]
        polalign = np.take(polalign, list(np.argwhere((freqs>=freqs.min()) & (freqs<=freqs.max())).squeeze()), 2)
        time = H.root.calibrator.polalign.time[:]
        print(f'Total circular standard deviation {circstd(polalign, nan_policy='omit')}')
        for idx, name in stats:
            vals = polalign[:, int(idx), :].T
            print(f'{name} circstd: {circstd(vals, nan_policy='omit')}')
            plt.imshow(vals, aspect='auto', origin='lower', cmap='RdBu_r', vmin=-np.pi/2, vmax=np.pi/2)
            plt.colorbar(label="Polalignment (radian)")  # Add a colorbar with a label

            y_ticks = np.divide(np.linspace(freqs.min(), freqs.max(), num=6), 1000000).astype(int)
            plt.yticks(np.linspace(plt.gca().get_ylim()[0], plt.gca().get_ylim()[1], num=6).astype(int), labels=y_ticks)
            x_ticks = np.linspace(0, (max(time)-min(time))/60, num=6).round(0).astype(int)
            plt.xticks(np.linspace(plt.gca().get_xlim()[0], plt.gca().get_xlim()[1], num=6).astype(int), labels=x_ticks)

            plt.xlabel('Time (min)')
            plt.ylabel('Frequency (MHz)')

            print(circstd(polalign[:, int(idx), :]))

            plt.title(name)
            plt.savefig(name+'.png')
            plt.close()


def get_polalign_all(calsol):
    stats = get_indices_int_stations(calsol)
    with tables.open_file(calsol) as H:
        polalign = H.root.calibrator.polalign.val[..., 1]
        freqs = H.root.calibrator.polalign.freq[:]
        freqs = freqs[(freqs > 120 * 1e6) & (freqs < 168 * 1e6)]
        polalign = np.take(polalign, list(np.argwhere((freqs >= freqs.min()) & (freqs <= freqs.max())).squeeze()), 2)
        time = H.root.calibrator.polalign.time[:]
        total_circstd = circstd(polalign, nan_policy='omit')
        print(f'Total circular standard deviation: {total_circstd}')

        # Set up a figure for the multigrid plot
        fig, axes = plt.subplots(
            nrows=1, ncols=len(stats), figsize=(50, 5), sharey=True, constrained_layout=True
        )
        fig.subplots_adjust(bottom=0.2)  # Make space for the colorbar

        for ax, (idx, name) in zip(axes, stats):
            vals = polalign[:, int(idx), :].T
            station_circstd = circstd(vals, nan_policy='omit')
            print(f'{name} circstd: {station_circstd}')

            im = ax.imshow(vals, aspect='auto', origin='lower', cmap='RdBu_r', vmin=-np.pi / 2, vmax=np.pi / 2)

            # Set x and y axis ticks
            y_ticks = np.divide(np.linspace(freqs.min(), freqs.max(), num=6), 1e6).astype(int)
            ax.set_yticks(np.linspace(0, vals.shape[0] - 1, num=6))
            ax.set_yticklabels(y_ticks, fontsize=24)
            x_ticks = np.linspace(0, (max(time) - min(time)) / 60, num=6).round(0).astype(int)
            ax.set_xticks(np.linspace(0, vals.shape[1] - 1, num=6))
            ax.set_xticklabels(x_ticks, fontsize=24)

            # Label axes
            ax.set_title(name, fontsize=30)
            ax.set_xlabel("Time (min)", fontsize=24)
            if ax is axes[0]:
                ax.set_ylabel("Frequency (MHz)", fontsize=24)

        # Add a horizontal colorbar
        cbar = fig.colorbar(im, ax=axes, orientation='vertical', fraction=0.3, pad=0.01)
        cbar.set_label("Polalignment (radian)", fontsize=24)

        # Save the figure
        plt.savefig("all_stations_polalign.png")
        plt.close()


if __name__ == '__main__':

    calsol = "cal_solutions.h5"
    calsol='gabrisol.h5'
    get_polalign_all(calsol)
