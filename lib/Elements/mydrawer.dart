// ignore_for_file: avoid_unnecessary_containers

import 'package:flutter/material.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      backgroundColor: Colors.transparent, // fond blanc
      child: SafeArea(
        top: true,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10) 
            )
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/articlesImages/LindaLogo2.png',
                            height: 150,
                            width: 150,
                          ),
                          const SizedBox(width: 30),
                        ],
                      ),
                    ),
                    const Divider(),
                    
                    const Divider(),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      child: Row(
                        children: [
                          
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
