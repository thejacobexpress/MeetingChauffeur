import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

int pageIndex = 0;

class navBar extends StatefulWidget {
  const navBar({super.key});

  @override
  State<navBar> createState() => _navBarState();
}
class _navBarState extends State<navBar> {
  @override
  Widget build(BuildContext context) {
    return NavigationBar(destinations: 
      [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.people),
          label: 'Meetings',
        ),
        NavigationDestination(
          icon: Icon(Icons.send),
          label: 'Send',
        ),
      ],
      onDestinationSelected: (int index) {
        setState(() {
          pageIndex = index;
        });
        safePrint("Selected destination: $index");
      },
    );
  }
}