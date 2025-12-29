import 'package:flutter/material.dart';
import 'package:app_thanh/AlarmClockScreen.dart';
import 'package:app_thanh/InformationScreen.dart';
import 'package:app_thanh/StopwatchScreen.dart';
import 'package:app_thanh/TemperatureConverterScreen.dart';
import 'package:app_thanh/TranslateScreen.dart';
import 'package:app_thanh/UnitConverterScreen.dart';
import 'package:app_thanh/YouTubePlayerScreen.dart';
import 'package:app_thanh/GroupInfoScreen.dart';
import 'package:app_thanh/app_colors.dart';
import 'package:app_thanh/screens/market_screen.dart';
import 'package:app_thanh/screens/facebook_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const TemperatureConverterScreen(),
    const UnitConverterScreen(),
    const YouTubePlayerScreen(),
    const AlarmClockScreen(),
    const StopwatchScreen(),
    const TranslateScreen(),
    const MarketScreen(), // Added Market
    const FacebookFeedScreen(), // Added FB Feed
    const GroupInfoScreen(),
    const InformationScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          "Ứng Dụng Đa Năng",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,

          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 10,
          unselectedFontSize: 9,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),

          iconSize: 20,

          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.thermostat_outlined),
              activeIcon: Icon(Icons.thermostat),
              label: 'Nhiệt độ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: 'Đơn vị',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_outlined),
              activeIcon: Icon(Icons.video_library),
              label: 'YouTube',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm_outlined),
              activeIcon: Icon(Icons.alarm),
              label: 'Báo thức',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'Bấm giờ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.translate_outlined),
              activeIcon: Icon(Icons.translate),
              label: 'Dịch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dynamic_feed_outlined),
              activeIcon: Icon(Icons.dynamic_feed),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Nhóm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],

          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
