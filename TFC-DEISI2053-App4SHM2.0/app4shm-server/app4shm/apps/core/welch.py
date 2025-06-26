import numpy as np
from scipy.interpolate import interpn as interpn
from scipy import signal
import traceback


class ReadingDTO:
    def __init__(self, timestamp, x, y, z):
        self.timestamp = timestamp
        self.x = x
        self.y = y
        self.z = z


def calculate_welch_frequencies(lines):
    data_stream = parse_lines_to_readings(lines)

    interpolated = interpolate_data_stream(data_stream)

    time_array = []
    x_array = []
    y_array = []
    z_array = []
    for i in interpolated:
        time_array.append(i.timestamp)
        x_array.append(i.x)
        y_array.append(i.y)
        z_array.append(i.z)
    welch_x_f, welch_x_pxx = calculate_welch_from_array(time_array, x_array)
    welch_y_f, welch_y_pxx = calculate_welch_from_array(time_array, y_array)
    welch_z_f, welch_z_pxx = calculate_welch_from_array(time_array, z_array)

    return welch_x_f.tolist(), welch_x_pxx.tolist(), welch_y_pxx.tolist(), welch_z_pxx.tolist()


# Constants and Parameters
INTERPOLATION_TYPE = 'linear'
TIME_INCREMENT = 20  # 20 ms


def interpolate_data_stream(data_stream: list[ReadingDTO]):
    data_times = []
    counter = 0
    data_x = []
    data_y = []
    data_z = []
    data_stream.sort(key=lambda x: x.timestamp)
    for i in data_stream:
        data_times.append(float(i.timestamp))
        data_x.append(i.x)
        data_y.append(i.y)
        data_z.append(i.z)
    while counter < len(data_times) - 1:
        count = data_times.count(data_times[counter])
        if count > 1:
            data_times.remove(data_times[counter])
            data_x.remove(data_x[counter])
            data_y.remove(data_y[counter])
            data_z.remove(data_z[counter])
            counter -= 1
        counter += 1
    t_start = data_times[0]
    t_end = data_times[len(data_times) - 1]
    t_interval_array = []
    start_me = t_start
    while start_me < t_end:
        t_interval_array.append(start_me)
        start_me += TIME_INCREMENT
    t_interval = np.array(t_interval_array)
    try:
        x_nd = interpn((np.array(data_times),), np.array(data_x), t_interval, INTERPOLATION_TYPE)
        y_nd = interpn((np.array(data_times),), np.array(data_y), t_interval, INTERPOLATION_TYPE)
        z_nd = interpn((np.array(data_times),), np.array(data_z), t_interval, INTERPOLATION_TYPE)
        inter_x = x_nd.tolist()
        inter_y = y_nd.tolist()
        inter_z = z_nd.tolist()
        ret_stream = []
        for i in range(0, len(t_interval)):
            ret_stream.append(ReadingDTO(
                                   timestamp=t_interval[i],
                                   x=inter_x[i],
                                   y=inter_y[i],
                                   z=inter_z[i]))
        return ret_stream
    except ValueError:
        track = traceback.format_exc()
        print(track)
        print("---------------------")
        print(data_times)
        return []


def calculate_welch_from_array(time: list[float], accelerometer_input: list[float]):
    delta_times = 0.02  # 20ms
    measuring_frequency = delta_times ** (-1)
    total_sample_number = len(time)  # measuring_frequency*len(time)
    n_segments = 3
    ls = int(np.round(total_sample_number / n_segments))
    overlap_perc = 50
    overlaped_samples = int(np.round(ls * overlap_perc / 100))
    discrete_fourier_transform_points = ls
    f, pxx = signal.welch(accelerometer_input, fs=measuring_frequency, nperseg=ls, noverlap=overlaped_samples,
                          nfft=discrete_fourier_transform_points)
    return f, pxx



    # f1 = np.reshape(f, (1, len(f)))
    # fs = 10e3
    # N = 1e5
    # amp = 2*np.sqrt(2)
    # freq = 1234
    # noise_power = 0.001 * fs / 2
    # time = np.arange(N) / fs
    # x = amp*np.sin(2*np.pi*freq*time)
    # x += np.random.normal(scale=np.sqrt(noise_power), size=time.shape)
    # f, Pxx_den = signal.welch(x, fs, nperseg=1024)

def calculate_aligned_welch_frequencies(interpolated: list[ReadingDTO]):
    time_array = [i.timestamp for i in interpolated]
    x_array = [i.x for i in interpolated]
    y_array = [i.y for i in interpolated]
    z_array = [i.z for i in interpolated]

    welch_x_f, welch_x_pxx = calculate_welch_from_array(time_array, x_array)
    welch_y_f, welch_y_pxx = calculate_welch_from_array(time_array, y_array)
    welch_z_f, welch_z_pxx = calculate_welch_from_array(time_array, z_array)

    return welch_x_f.tolist(), welch_x_pxx.tolist(), welch_y_pxx.tolist(), welch_z_pxx.tolist()

def interpolate_data_stream_aligned(data_stream: list[ReadingDTO]) -> list[ReadingDTO]:
    if not data_stream:
        return []

    data_stream.sort(key=lambda x: x.timestamp)

    data_times, data_x, data_y, data_z = [], [], [], []
    seen = set()
    for reading in data_stream:
        if reading.timestamp not in seen:
            seen.add(reading.timestamp)
            data_times.append(reading.timestamp)
            data_x.append(reading.x)
            data_y.append(reading.y)
            data_z.append(reading.z)

    if len(data_times) < 2:
        return []

    TIME_INCREMENT = 20  # ms

    t_start = round(int(data_times[0]) / TIME_INCREMENT) * TIME_INCREMENT
    t_end = ((int(data_times[-1]) // TIME_INCREMENT) + 1) * TIME_INCREMENT

    t_interval = np.arange(t_start, t_end + 1, TIME_INCREMENT)

    return [
        ReadingDTO(timestamp=int(t), x=x, y=y, z=z)
        for t, x, y, z in zip(t_interval, data_x, data_y, data_z)
    ]



def align_multiple_streams(multiple_lines):
    device_data_streams = [parse_lines_to_readings(lines) for lines in multiple_lines]

    interpolated_data_streams = [
        interpolate_data_stream_aligned(data_stream) for data_stream in device_data_streams
    ]


    timestamp_sets = [set(r.timestamp for r in stream) for stream in interpolated_data_streams]
    common_timestamps = set.intersection(*timestamp_sets)
    common_timestamps = sorted(common_timestamps)

    aligned_data_streams = []
    for stream in interpolated_data_streams:
        filtered = [r for r in stream if r.timestamp in common_timestamps]
        aligned_data_streams.append(filtered)

    return aligned_data_streams

def calculate_mean_welch_frequencies(aligned_data_streams):
    sum_x, sum_y, sum_z, sum_freq = None, None, None, None
    for data_stream in aligned_data_streams:
        freqs, x_list, y_list, z_list = calculate_aligned_welch_frequencies(data_stream)

        if sum_x is None:
            sum_x = np.array(x_list)
            sum_y = np.array(y_list)
            sum_z = np.array(z_list)
            sum_freq = np.array(freqs)
        else:
            sum_x += np.array(x_list)
            sum_y += np.array(y_list)
            sum_z += np.array(z_list)
            sum_freq += np.array(freqs)

    # calculate mean
    avg_x = (sum_x / len(aligned_data_streams)).tolist()
    avg_y = (sum_y / len(aligned_data_streams)).tolist()
    avg_z = (sum_z / len(aligned_data_streams)).tolist()
    avg_freq = (sum_freq / len(aligned_data_streams)).tolist()

    return avg_freq, avg_x, avg_y, avg_z

def parse_lines_to_readings(lines):
    data_stream = []
    for line in lines:
        if len(line.strip()) > 0:
            parts = line.strip().split(";")
            if len(parts) >= 4:
                timestamp = float(parts[0])
                x = float(parts[1])
                y = float(parts[2])
                z = float(parts[3])
                reading = ReadingDTO(timestamp, x, y, z)
                data_stream.append(reading)
    return data_stream

def readings_to_lines(readings):
    lines = []
    for r in readings:
        line = f"{int(r.timestamp)};{r.x};{r.y};{r.z}"
        lines.append(line)
    return lines
