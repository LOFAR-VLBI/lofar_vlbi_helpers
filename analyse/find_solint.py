import numpy as np
import matplotlib.pyplot as plt
from numpy.random import normal

# pretty plots
try:
    import scienceplots
    plt.style.use(['science','ieee'])
except:
    pass


# set std score, for which you want to find the solint
optimal_score = 0.5

def get_circvar(phasediff):
    """
    Get circular variance

    From: https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.circstd.html

    :param phasediff: phase difference between XX and YY
    """
    A = np.cos(phasediff).mean()
    B = np.sin(phasediff).mean()
    R = np.sqrt(A ** 2 + B ** 2)
    return -2 * np.log(R)


def get_circstd(phasediff):
    """
    Get circular std
    """
    return np.sqrt(get_circvar(phasediff))


def plot_C(C, title=None):
    """
    Plot circstd score in function of solint for given C

    :param C: constant defining the noise level
    """
    normal_sigmas = [n / 10 for n in range(0, 100)]
    values = [get_circstd(normal(0, n, 10000)) for n in normal_sigmas]
    x = C / (np.array(normal_sigmas) ** 2) * 10

    plt.plot(x, values)
    plt.plot([0, 100], [optimal_score, optimal_score], color='red')
    plt.xlim(0, 20)
    plt.xlabel("solint (min)")
    plt.ylabel("circstd score")
    if title is not None:
        plt.title(title)
    plt.show()


def circvar_to_normvar(circ_var):
    """
    Convert circular variance to normal variance

    return: circular variance
    """
    #     return -2*np.log(1-circ_var/np.pi)
    return (1 - np.exp(-circ_var / 2))


def get_C(phasediff):
    """
    Get constant defining the normal circular distribution

    See:
    - https://en.wikipedia.org/wiki/Wrapped_normal_distribution
    - https://en.wikipedia.org/wiki/Yamartino_method
    - https://en.wikipedia.org/wiki/Directional_statistics


    :param phasediff: phase difference between XX and YY

    :return: C
    """
    circvar = get_circvar(phasediff)
    normvar = circvar_to_normvar(circvar)
    solint = 1  # by setting it to 1, the function returns how many times solution interval increase
    return normvar * solint


def get_optimal_solint(phasediff, C):
    """
    Get optimal solution interval from phasediff, given C

    :param phasediff: phase difference between XX and YY
    :param solint: solution interval

    :return: value corresponding with increase solution interval
    """
    C = get_C(phasediff)
    optimal_cirvar = optimal_score ** 2
    return C / (circvar_to_normvar(optimal_cirvar)) / 2


if __name__ == "__main__":

    # random data
    x = np.cos(normal(0, 1.7, 100000))
    y = np.sin(normal(0, 1.6, 100000))
    data = np.angle(x + y * 1j)

    # find C
    C = get_C(data)
    print("C=" + str(round(C, 3)) + " for this distribution")
    plot_C(C, "T=" + str(round(get_optimal_solint(data, C), 2)) + " min")