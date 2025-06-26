import numpy as np


def score_mahalanobis_shm(x, mean, cov):
    return np.dot(np.dot((x - mean), np.linalg.inv(cov)), np.transpose((x - mean)))


# current_frequencies is a list of frequencies that we want to test against history.
# at this point, len(current_frequencies) must be 3
# history_frequencies is a list of list of frequencies, previously calculated and stored in the db
def mahalanobis(history_frequencies, current_frequencies):
    assert len(current_frequencies) == 3

    m = 3
    # n = len(group)

    testPoint = np.array(current_frequencies)

    PFA = 0.05
    degFreedom = m
    # UCL = 3.8415 # m = 1
    # UCL = 5.9915 # m = 2
    UCL = 7.8147  # m = 3
    # print(UCL)
    values = np.array([])

    for freq in history_frequencies:
        assert len(freq) == 3
        values = np.append(values, freq[0])
        values = np.append(values, freq[1])
        values = np.append(values, freq[2])

    values = np.reshape(values, (-1, 3))
    # print(values)
    covMatrix = np.cov(np.transpose(values), bias=True)
    # print(covMatrix)
    mean = np.mean(values, axis=0)
    # print(mean)
    DI = []

    for value in values:
        DI.append(score_mahalanobis_shm(value, mean, covMatrix))
    DI.append(score_mahalanobis_shm(testPoint, mean, covMatrix))
    # print(DI)
    if DI[-1] <= UCL:
        return True, UCL, DI
    else:
        return False, UCL, DI
