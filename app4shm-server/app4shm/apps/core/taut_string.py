import json
import numpy as np

def tension_forces(m, L, frequencies):
    # forces for each frequency
    force1 = calculate_tension_force(m, L, frequencies[0], 1)
    force2 = calculate_tension_force(m, L, frequencies[1], 2)
    force3 = calculate_tension_force(m, L, frequencies[2], 3)

    # cable force
    cable_force = calculate_tension_force_mean(m, L,frequencies)

    # return force1; force2; force3; cable force
    return force1, force2, force3, cable_force

def calculate_tension_force_mean(m, L, frequencies):
    # Number of freq (k)
    k = len(frequencies)

    # Verify if k is empty
    if k == 0:
        raise ValueError(f"Frequencies list can't be empty. Received: {frequencies}")

    mean_frequency = sum(f / n for n, f in enumerate(frequencies, start=1)) / k

    # Return tension force (F) kN
    return round((4 * m * L ** 2 * mean_frequency ** 2) / 1000)

def calculate_tension_force(m, L, freq, k):
    mean_frequency = freq / k

    # Return tension force (F) kN
    return round((4 * m * L ** 2 * mean_frequency ** 2) / 1000)