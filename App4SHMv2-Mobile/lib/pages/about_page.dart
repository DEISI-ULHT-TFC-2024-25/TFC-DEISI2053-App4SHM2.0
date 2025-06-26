import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = 'Loading...';
  String _buildNumber = 'Loading...';

  _loadVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = "v${packageInfo.version}";
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  void initState() {
    _loadVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('About App4SHM')
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.light
                        ? 'assets/logo-white.png'
                        : 'assets/logo-dark.png',
                    height: 150,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        _version,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 1
                            ..color = Theme.of(context).colorScheme.primary,
                        )
                    ),
                    const SizedBox(width: 10),
                    Text(
                        "($_buildNumber)",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.secondary,
                        )
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                    "App4SHM is a smartphone application for structural health monitoring (SHM) of bridges or other civil structures to assess their condition after a catastrophic event or when required by authorities and stakeholders. The application interrogates the phone’s internal accelerometer to measure structural accelerations and applies artificial intelligence techniques to detect damage in almost real time.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    )
                ),
                const SizedBox(height: 30),
                Image.asset(
                  'assets/bridge.webp',
                  width: double.infinity,
                ),
                const SizedBox(height: 30),
                Text(
                    "Working principle",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )
                ),
                const SizedBox(height: 10),
                const Text(
                    "The way a bridge vibrates is like a ‘fingerprint’ of that bridge! So, the next time you are on a bridge feeling shaken by the passing of a truck, think that the vibration you are feeling belongs solely to that bridge, and that there is no other bridge in the world that would vibrate in the same way. Bridges are like the strings of a guitar: no two strings would play the same sound. App4SHM simply checks if a bridge has gone ‘out of tune’. For that, it uses the accelerometers installed on the mobile phone to measure the accelerations of the bridge under normal operational conditions. The vibration frequencies of the bridge are extracted from the acceleration time series and compared with those measured some time ago to see if the changes suggest damage. Transient changes are probably not indication of damage (perhaps the measurements were made at a rush hour and the mass of the traffic influenced the vibration of the bridge), but sustained and significant changes should be an alarm signal and motivate a detailed inspection of the bridge.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    )
                ),
                const SizedBox(height: 50),
                const Text(
                    "This is a R&D project funded by COFAC, involving students and professors from ULHT's civil "
                        "engineering and computer science courses: Eloi Figueiredo, Hugo Rebelo, Ionut Moldovan,"
                        " Luís Silva, Nuno Penim, Paulo Oliveira, Jorge Lobão, Rodrigo Félix, Diogo Fonseca, Gab"
                        "riel Pacheco and Pedro Alves.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    )
                ),
              ],
            ),
          ),
        )
    );
  }
}
