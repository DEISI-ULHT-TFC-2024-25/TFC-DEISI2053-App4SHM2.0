# APP4SHM

App4SHM is a smartphone application for structural health monitoring (SHM) of bridges or other civil structures to assess their condition after a catastrophic event or when required by authorities and stakeholders. The application interrogates the phone’s internal accelerometer to measure structural accelerations and applies artificial intelligence techniques to detect damage in almost real time.

### Run instructions:
The app must be always in release mode to successfully connect to DEISI servers when the local django server is not available. To do this, add `--release` to the flutter run command.

### Demonstrative video
https://www.youtube.com/watch?v=l7dSopnTRJ0&ab_channel=RodrigoFelix

## Working principle
The way a bridge vibrates is like a ‘fingerprint’ of that bridge! So, the next time you are on a bridge feeling shaken by the passing of a truck, think that the vibration you are feeling belongs solely to that bridge, and that there is no other bridge in the world that would vibrate in the same way. Bridges are like the strings of a guitar: no two strings would play the same sound.

App4SHM simply checks if a bridge has gone ‘out of tune’. For that, it uses the accelerometers installed on the mobile phone to measure the accelerations of the bridge under normal operational conditions. The vibration frequencies of the bridge are extracted from the acceleration time series and compared with those measured some time ago to see if the changes suggest damage.

Transient changes are probably not indication of damage (perhaps the measurements were made at a rush hour and the mass of the traffic influenced the vibration of the bridge), but sustained and significant changes should be an alarm signal and motivate a detailed inspection of the bridge.

## How does it work?
Do you want to know current state condition of your structure? Just place the smartphone on it, record an acceleration time series, and after few seconds you should be able to pick the natural frequencies. Is the structure damaged? After building a reference data set with multiple observations, you should be able to compare a new observation with past ones and raise a flag about the structure condition!

## Software architecture
App4SHM is composed of two software components: a mobile application and a computational platform hosted by a remote server. The mobile application is developed in Kotlin and is compatible with devices running Android 5 operating system (or higher). It implements a navigation mechanism with four tabs corresponding to the four steps in the damage detection process:

- Structure Identification
- Data Acquisition
- Frequency Extraction
- Damage Detection

## Applicability
App4SHM can be potentially applied to any kind of civil structure that vibrates significantly under operational and environmental conditions. It has been tested on data sets from two real-world bridges under operational and environmental variability in Brazil, showing promising results in terms of feature extraction and damage detection.

## Technical stuff

Requires flutter 3.19.3

## Versions

1.1.0 (15/05/2025) - Besides several optimizations, app4shm now includes a new module for cable tension estimation and pathology detection in cable-stayed bridges.