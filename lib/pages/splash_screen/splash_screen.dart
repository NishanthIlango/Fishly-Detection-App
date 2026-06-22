import 'dart:async';

import 'package:fish_app/pages/home_screen/home_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }


  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(child: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 18, 84, 137),
                    Colors.lightBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4,0.7],
                  tileMode: TileMode.repeated
                )
              ),
          )),
          Positioned(
            
            child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/image/splash_screen.png',),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ),
          Positioned(
              top: 180,
              child: Padding(
                padding: const EdgeInsets.all(45.0),
                child: RichText(
                  text: const TextSpan(
                    text: "Fish Detection App",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            // Positioned(
            //   top: 670,
            //   child: Padding(
            //     padding: const EdgeInsets.only(left: 40),
            //     child: InkWell(
            //       onTap: () {
            //           Navigator.push( 
            //         context, 
            //         PageRouteBuilder( 
            //           transitionsBuilder: 
            //               (context, animation, secondaryAnimation, child) { 
            //                 const begin = Offset(1.0, 0.0);
            //                 const end = Offset.zero;
            //                 const curve = Curves.ease;

            //                 var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            //             return SlideTransition(
            //               position: animation.drive(tween),
            //               child: child,
            //             ); 
            //           }, 
            //           transitionDuration: Duration(milliseconds: 100), 
            //           pageBuilder: (BuildContext context, 
            //               Animation<double> animation, 
            //               Animation<double> secondaryAnimation) { 
            //             return HomeScreen(); 
            //           }, 
            //         ), 
            //       );
            //       },
            //       child: Container(
            //         height: 65,
            //         width: MediaQuery.of(context).size.width-75,
                    
            //         decoration: const BoxDecoration(
            //           shape: BoxShape.rectangle,
            //           color: Colors.white,
            //           borderRadius: BorderRadius.all(Radius.circular(20))
            //         ),
            //         child: const Center(child: Text("Get Started",
            //         style: TextStyle(
            //           color: Colors.black,
            //           fontSize: 20,
            //           fontWeight: FontWeight.bold
            //         )
            //         )),
            //       ),
            //     ),
            //   ),
            // )
        ],
      ),
    );
  }
}