import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hellogram/domain/blocs/auth/auth_bloc.dart';
import 'package:hellogram/domain/blocs/user/user_bloc.dart';
import 'package:hellogram/domain/services/auth.dart';
import 'package:hellogram/ui/helpers/helpers.dart';
import 'package:hellogram/ui/screens/home/home_page.dart';
import 'package:hellogram/ui/screens/login/login_page.dart';
import 'package:hellogram/ui/screens/login/started_page.dart';
import 'package:hellogram/ui/themes/colors_frave.dart';
import 'package:hellogram/ui/widgets/widgets.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({Key? key}) : super(key: key);

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.8).animate(_animationController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _animationController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _animationController.forward();
            }
          });

    _animationController.forward();

    authenticateUserOnStart();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void authenticateUserOnStart() async {
    bool isAuthenticated = await AuthService.authenticateUser();
    final userBloc = BlocProvider.of<UserBloc>(context);
    if (isAuthenticated) {
      BlocListener<AuthBloc, AuthState>(listener: (context, state) {
        if (state is SuccessAuthentication) {
          userBloc.add(OnGetUserAuthenticationEvent());
          Navigator.pushAndRemoveUntil(
              context, routeSlide(page: const HomePage()), (_) => false);
        }
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StartedPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.black,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: SizedBox(
            height: 200,
            width: 150,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (_, child) => Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Image.asset(
                      'assets/img/hello.png',
                      color: Colors.white,
                      height: 100,
                      width: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                const TextCustom(text: 'LOADING...', color: Colors.white),
              ],
            ),
          ),
        ),
      ),
      //),
    );
  }
}
