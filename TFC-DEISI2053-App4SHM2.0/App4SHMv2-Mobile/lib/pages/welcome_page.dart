import 'package:app4shm/pages/structures_page.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pages = [
  const PageData(
    icon: FaIcon(FontAwesomeIcons.heartPulse),
    title: "Welcome to\nApp4SHM",
    bgColor: Color(0xFF01dea0),
    //textColor: Color(0xFF01dea0),
  ),
  const PageData(
    icon: FaIcon(FontAwesomeIcons.bridge),
    title: "Pick the type\nof structure",
    bgColor: Color(0xffCFFFCE),
  ),
  const PageData(
    icon: FaIcon(FontAwesomeIcons.bridgeCircleCheck),
    title: "Outras páginas\nestarão aqui",
    bgColor: Color(0xffFCF1B5),
    //textColor: Color(0xffFFE0E1),
  ),
  const PageData(),
];

class PageData {
  final String? title;
  final FaIcon? icon;
  final Color bgColor;
  final Color textColor;

  const PageData({
    this.title,
    this.icon,
    this.bgColor = Colors.white,
    this.textColor = Colors.black,
  });
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool showNextButton = true;

  @override
  void initState() {
    // TODO: implement initState
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isNewUser', false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: ConcentricPageView(
        colors: pages.map((p) => p.bgColor).toList(),
        radius: screenWidth * 0.1,
        // curve: Curves.ease,
        // dont show this button on last page
        nextButtonBuilder: (context) => showNextButton ?  Padding(
          padding: const EdgeInsets.only(left: 3), // visual center
          child: Icon(
            Icons.navigate_next,
            size: screenWidth * 0.08,
            color: Colors.black,
          ),
        ) : Padding(
              padding: const EdgeInsets.only(left: 3), // visual center
              child: Icon(
              Icons.star,
              size: screenWidth * 0.08,
              color: Colors.black,
            ),
          ),
        itemCount: pages.length,
        // duration: const Duration(milliseconds: 1500),
        // opacityFactor: 2.0,
        // scaleFactor: 0.2,
        // verticalPosition: 0.7,
        // direction: Axis.vertical,
        // itemCount: pages.length,
        // physics: NeverScrollableScrollPhysics(),
        itemBuilder: (index) {
          // on last page, show a button
          if (index == pages.length - 1) {
            showNextButton = false;
            return Center(
              child: CupertinoButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const StructuresPage(),
                    ),
                  );
                },
                child: const Text('Get Started'),
              ),
            );
          } else {
            final page = pages[index % pages.length];
            return SafeArea(
              child: _Page(page: page),
            );
          }
        },
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final PageData page;

  const _Page({Key? key, required this.page}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    space(double p) => SizedBox(height: screenHeight * p / 100);
    return Column(
      children: [
        space(10),
        Icon(
            page.icon!.icon,
            size: 170,
            color: page.textColor
        ),
        space(8),
        _Text(
          page: page,
          style: TextStyle(
            fontSize: screenHeight * 0.046,
          ),
        ),
      ],
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    Key? key,
    required this.page,
    this.style,
  }) : super(key: key);

  final PageData page;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      page.title ?? '',
      style: TextStyle(
        color: page.textColor,
        fontWeight: FontWeight.w600,
        fontFamily: 'Helvetica',
        letterSpacing: 0.0,
        fontSize: 18,
        height: 1.2,
      ).merge(style),
      textAlign: TextAlign.center,
    );
  }
}