import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../tricolor_background.dart';
import 'add_form_tab.dart';
import 'records_list_tab.dart';
import 'reports_tab.dart';
import 'setup_tab.dart';
import 'today_followups_page.dart'; // Adjust the path as needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _owner = "owner";
  int _todayFollowupCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOwner();
    _loadTodayFollowupCount();
  }

  Future<void> _loadOwner() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _owner = prefs.getString('owner_name') ?? 'owner';
    });
  }

  Future<void> _loadTodayFollowupCount() async {
    final count = await DatabaseHelper.instance.getTodayFollowupCount();
    setState(() {
      _todayFollowupCount = count;
    });
  }

  // Call this after adding a new record (use a callback or state management)
  void refreshFollowupCount() {
    _loadTodayFollowupCount();
  }

Widget _buildFollowupBadge(BuildContext context) {
  if (_todayFollowupCount == 0) return const SizedBox.shrink();
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        //MaterialPageRoute(builder: (_) => const TodayFollowupsPage()),
        MaterialPageRoute(
          builder: (_) => TodayFollowupsPage(onClose: refreshFollowupCount),
       )
      );
    },
    child: Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.yellow[700],
        shape: BoxShape.circle,
      ),
      child: Text(
        '$_todayFollowupCount',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JanSampark $_owner'),
        actions: [
          //anand _buildFollowupBadge(),
          _buildFollowupBadge(context),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF9933),         // Saffron for selected tab
          unselectedLabelColor: Colors.white,          // White for unselected tabs
          tabs: const [
            Tab(text: 'Add Record', icon: Icon(Icons.add)),
            Tab(text: 'All Records', icon: Icon(Icons.list)),
            Tab(text: 'Reports', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Setup', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TricolorBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            AddFormTab(onRecordAdded: refreshFollowupCount),
            RecordListTab(onRecordAdded: refreshFollowupCount),
            const ReportsTab(),
            const SetupTab(),
          ],
        ),
      ),
    );
  }
}

