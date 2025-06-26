import 'package:app4shm/components/alert_dialogs.dart';
import 'package:app4shm/services/login_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../providers/app_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController emailFieldController = TextEditingController();
  final TextEditingController passwordFieldController = TextEditingController();
  bool _isloading = false;

  Future<bool> isNewUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isNewUser') ?? true;
  }

  _auth({ bool guest = false }) {
    final userid = !guest ? emailFieldController.text : 'guest';
    final password = !guest ? passwordFieldController.text : 'guestSHM2022';
    // print('userid: $userid, password: $password');
    setState(() => _isloading = true);
    LoginService().sendLoginRequest(userid, password).then((value) {
      setState(() => _isloading = false);
      if (value) {
        Provider.of<AppProvider>(context, listen: false).setUser(User(userid));
        Navigator.popAndPushNamed(context, '/structures');
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invalid credentials'),
            content: const Text('The userid or password you entered is incorrect.'),
            actions: [
              TextButton(
                child: const Text('Try again'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isloading ? const Center(child: CircularProgressIndicator()) :
      SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 50, 0, 50),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.light
                          ? 'assets/logo-white.png'
                          : 'assets/logo-dark.png',
                      height: 150,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: TextField(
                      // make background lighter than default
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      controller: emailFieldController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: TextField(
                      // make background lighter than default
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                      obscureText: true,
                      controller: passwordFieldController,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _auth(),
                  child: const Text('Sign in'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: TextButton(
                onPressed: () => _auth(guest: true),
                child: const Text('Sign in as guest'),
              ),
            ),
            TextButton(
              onPressed: () => showAlertDialog(
                      context: context,
                      title: 'Get full access',
                      content: 'This application can be used for free by any civil engineering researchers and practitioners wanting to experiment with SHM for real structures. '
                          'Just send an email to app4shm@ulusofona.pt with your information and we will be happy to create a user for you.',
                    ),
                    child: const Text('Want full access?'),
            ),
          ],
        ),
      ),
    );
  }
}
