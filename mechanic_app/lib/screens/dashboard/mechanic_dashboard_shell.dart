
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/theme/mechanic_theme.dart';
import '../auth/mechanic_login_screen.dart';

class MechanicDashboardShell extends StatefulWidget {
  final String accessToken;

  const MechanicDashboardShell({
    super.key,
    required this.accessToken,
  });

  @override
  State<MechanicDashboardShell> createState() =>
      _MechanicDashboardShellState();
}

class _MechanicDashboardShellState extends State<MechanicDashboardShell> {
  int _currentIndex = 0;
  bool _isOnline = false;
  bool _isLoading = true;
  String? _loadError;
  Map<String, dynamic>? _activeJob;
  Map<String, dynamic>? _mechanic;
  Map<String, dynamic>? _user;
  final List<Map<String, dynamic>> _requests = [];
  final List<Map<String, dynamic>> _allRequests = [];
  final List<Map<String, String>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Uri _apiUri(String path) {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${widget.accessToken}',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _getJson(String path) async {
    final response = await http.get(_apiUri(path), headers: _authHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GET $path failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body);
  }

  Future<void> _postAction(String path) async {
    final response = await http.post(_apiUri(path), headers: _authHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) detail = decoded['detail'].toString();
      } catch (_) {}
      throw Exception(detail);
    }
  }

  String _stringValue(dynamic value, [String fallback = 'Not provided']) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  Map<String, dynamic> _displayRequest(Map<String, dynamic> raw) {
    final apiStatus = _stringValue(raw['status'], 'PENDING').toUpperCase();
    final lat = raw['latitude'];
    final lon = raw['longitude'];
    return {
      ...raw,
      'driver': _stringValue(raw['driver_name'], 'Driver'),
      'phone': _stringValue(raw['phone_number']),
      'vehicle': _stringValue(raw['vehicle_info'], _stringValue(raw['vehicle_type'], 'Vehicle')),
      'category': _stringValue(raw['category'], 'General Repair'),
      'issue': _stringValue(raw['issue_description'], 'No issue description'),
      'distance': 'GPS location',
      'location': lat == null || lon == null ? 'Location not provided' : 'Lat $lat, Lon $lon',
      'apiStatus': apiStatus,
      'step': apiStatus == 'IN_PROGRESS' ? 4 : 1,
      'status': apiStatus == 'IN_PROGRESS' ? 'Repair in progress' : 'Accepted',
    };
  }

  Future<void> _loadDashboard({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() { _isLoading = true; _loadError = null; });
    }
    try {
      final results = await Future.wait([
        _getJson('/auth/me'),
        _getJson('/mechanics/'),
        _getJson('/assistance/'),
      ]);
      final userData = Map<String, dynamic>.from(results[0] as Map);
      final mechanicList = (results[1] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      final userId = userData['id'];
      Map<String, dynamic>? mechanicData;
      for (final candidate in mechanicList) {
        if (candidate['user_id'] == userId) { mechanicData = candidate; break; }
      }
      if (mechanicData == null) throw Exception('No mechanic profile is linked to this login. Create the mechanic profile first.');
      final rawRequests = (results[2] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      final mapped = rawRequests.map(_displayRequest).toList();
      final pending = mapped.where((item) => item['apiStatus'] == 'PENDING').toList();
      final assigned = mapped.where((item) => item['mechanic_id'] == mechanicData!['id'] && (item['apiStatus'] == 'ACCEPTED' || item['apiStatus'] == 'IN_PROGRESS')).toList();
      final rawCategories = mechanicData['service_categories'];
      final categories = rawCategories is List
          ? rawCategories.map((v) => v.toString()).where((v) => v.trim().isNotEmpty).toList()
          : _stringValue(rawCategories, '').split(RegExp(r'[,;]')).map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
      if (!mounted) return;
      setState(() {
        _user = userData;
        _mechanic = mechanicData;
        _isOnline = mechanicData!['is_available'] == true ||
            mechanicData['availability'] == true ||
            _stringValue(mechanicData['status'], '').toUpperCase() == 'AVAILABLE';
        _allRequests..clear()..addAll(mapped);
        _requests..clear()..addAll(pending);
        _services..clear()..addAll(categories.map((name) => {'name': name, 'icon': 'service'}));
        _activeJob = assigned.isEmpty ? null : assigned.first;
        if (_activeJob == null && _currentIndex == 1) _currentIndex = 0;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _isLoading = false; _loadError = error.toString().replaceFirst('Exception: ', ''); });
    }
  }

  static const Color _blue = Color(0xFF4D8DFF);
  static const Color _blueDark = Color(0xFF152C4D);
  static const Color _green = Color(0xFF35D39A);
  static const Color _red = Color(0xFFFF647C);

  void _message(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color ?? MechanicTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _toggleOnline(bool value) {
    _message('Availability changes are not supported by the backend yet. Current server status: ${_isOnline ? 'online' : 'offline'}.');
  }

  Future<void> _acceptJob(Map<String, dynamic> request) async {
    if (!_isOnline || _activeJob != null) {
      _message('Your mechanic profile must be available, and you must not have an active job.');
      return;
    }
    try {
      await _postAction('/assistance/${request['id']}/accept');
      await _loadDashboard();
      if (!mounted) return;
      setState(() => _currentIndex = 1);
      _message('Request accepted by the server.', color: _green);
    } catch (error) {
      _message('Could not accept request: ${error.toString().replaceFirst('Exception: ', '')}', color: _red);
      await _loadDashboard(showLoader: false);
    }
  }

  void _declineJob(dynamic id) {
    _message('Decline is not supported by the backend yet. Request #$id remains pending.');
  }

  Future<void> _advanceJob() async {
    final job = _activeJob;
    if (job == null) return;
    final id = job['id'];
    final status = _stringValue(job['apiStatus']).toUpperCase();
    try {
      if (status == 'ACCEPTED') {
        await _postAction('/assistance/$id/start');
        await _loadDashboard();
        if (mounted) _message('Job started and saved to the server.', color: _green);
      } else if (status == 'IN_PROGRESS') {
        await _postAction('/assistance/$id/complete');
        await _loadDashboard();
        if (mounted) { setState(() => _currentIndex = 0); _message('Job completed and saved to the server.', color: _green); }
      } else {
        _message('This request is not in a state that can be updated.');
      }
    } catch (error) {
      _message('Could not update job: ${error.toString().replaceFirst('Exception: ', '')}', color: _red);
      await _loadDashboard(showLoader: false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out of the mechanic portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MechanicLoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildRequests(),
      _buildActiveJob(),
      _buildStats(),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_blue, Color(0xFF35C9F5)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.car_repair_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VehicleAssist',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Workshop Partner',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: (_isOnline ? _green : MechanicTheme.textMuted)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_isOnline ? _green : MechanicTheme.textMuted)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isOnline ? _green : MechanicTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: _isOnline ? _green : MechanicTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _requests.isNotEmpty && _isOnline,
              label: Text('${_requests.length}'),
              child: const Icon(Icons.grid_view_rounded),
            ),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _activeJob != null,
              child: const Icon(Icons.handyman_outlined),
            ),
            selectedIcon: const Icon(Icons.handyman_rounded),
            label: 'Active Job',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Workshop',
          ),
        ],
      ),
    );
  }

  // REQUESTS
  Widget _buildRequests() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          const Text('Could not load live dashboard data'),
          const SizedBox(height: 8),
          Text(_loadError!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => _loadDashboard(), icon: const Icon(Icons.refresh), label: const Text('Try again')),
        ]),
      ));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        _sectionLabel('PARTNER DASHBOARD'),
        const SizedBox(height: 8),
        Text(
          'Good to see you, ${_stringValue(_mechanic?['workshop_name'], _stringValue(_mechanic?['name'], 'Mechanic'))}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Manage roadside assistance requests from one place.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _buildOnlineCard(),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'New requests',
                '${_requests.length}',
                Icons.notifications_active_outlined,
                _blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'Active job',
                _activeJob == null ? '0' : '1',
                Icons.handyman_outlined,
                _green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _sectionLabel('ASSISTANCE FEED'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Nearby requests',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            TextButton.icon(onPressed: () => _loadDashboard(), icon: const Icon(Icons.refresh, size: 16), label: const Text('Refresh')),
          ],
        ),
        const SizedBox(height: 14),
        if (!_isOnline)
          _emptyState(
            Icons.power_settings_new_rounded,
            'You are offline',
            'Your mechanic profile is marked unavailable in the backend.',
          )
        else if (_activeJob != null)
          _emptyState(
            Icons.assignment_turned_in_outlined,
            'One job in progress',
            'Complete your current job before accepting another.',
          )
        else if (_requests.isEmpty)
          _emptyState(
            Icons.radar_rounded,
            'No pending requests',
            'The backend has no pending requests right now. Use Refresh to check again.',
          )
        else
          ..._requests.map(_requestCard),
      ],
    );
  }

  Widget _buildOnlineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C416D), Color(0xFF152638), Color(0xFF18202C)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _blue.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: _blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'Ready for new jobs?' : 'Currently offline',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isOnline
                          ? 'Your partner status is active.'
                          : 'Turn on availability to continue.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _isOnline ? 'Accepting requests' : 'Requests paused',
                  style: TextStyle(
                    color: _isOnline ? _green : MechanicTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Switch(value: _isOnline, activeThumbColor: _green, onChanged: null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _pill(_stringValue(request['category'], 'General Repair'), _blue),
                const Spacer(),
                const Icon(Icons.near_me_outlined, size: 16, color: _blue),
                const SizedBox(width: 5),
                Text(
                  _stringValue(request['distance']),
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              _stringValue(request['driver'], 'Driver'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _detailLine(Icons.directions_car_outlined, _stringValue(request['vehicle'], 'Vehicle')),
            const SizedBox(height: 6),
            _detailLine(Icons.location_on_outlined, _stringValue(request['location'])),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: MechanicTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _stringValue(request['issue'], 'No issue description'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MechanicTheme.textPrimary,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineJob(request['id']),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _activeJob == null
                        ? () => _acceptJob(request)
                        : null,
                    icon: const Icon(Icons.check_circle_outline, size: 19),
                    label: const Text('Accept request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ACTIVE JOB
  Widget _buildActiveJob() {
    final job = _activeJob;

    if (job == null) {
      return _emptyState(
        Icons.handyman_outlined,
        'No active job',
        'Accept a request to see customer details and service progress here.',
        padded: true,
      );
    }

    final step = job['step'] as int;
    final stages = [
      'Request accepted',
      'En route to customer',
      'Arrived at location',
      'Repair in progress',
    ];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionLabel('SERVICE MANAGEMENT'),
        const SizedBox(height: 8),
        Text(
          'Active service',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_blueDark, MechanicTheme.surface],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _blue.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded, color: _blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Request #${job['id']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _pill(_stringValue(job['category'], 'General Repair'), _blue),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _stringValue(job['status']),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _green,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _stringValue(job['vehicle'], 'Vehicle'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _panel(
          title: 'Customer information',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailLine(Icons.person_outline, _stringValue(job['driver'], 'Driver')),
              const SizedBox(height: 12),
              _detailLine(Icons.phone_outlined, _stringValue(job['phone'])),
              const SizedBox(height: 12),
              _detailLine(Icons.location_on_outlined, _stringValue(job['location'])),
              const SizedBox(height: 12),
              _detailLine(Icons.build_outlined, _stringValue(job['issue'], 'No issue description')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          title: 'Service progress',
          child: Column(
            children: List.generate(stages.length, (index) {
              final stageNumber = index + 1;
              final complete = step >= stageNumber;
              final active = step == stageNumber;

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    Icon(
                      complete
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: active
                          ? _blue
                          : complete
                              ? _green
                              : MechanicTheme.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stages[index],
                        style: TextStyle(
                          color: complete
                              ? MechanicTheme.textPrimary
                              : MechanicTheme.textMuted,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (active) _pill('CURRENT', _blue),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _advanceJob,
          icon: Icon(
            step == 4 ? Icons.check_circle_outline : Icons.arrow_forward,
          ),
          label: Text(_stringValue(job['apiStatus']).toUpperCase() == 'ACCEPTED' ? 'Start job' : 'Complete job'),
        ),
        const SizedBox(height: 8),
        Text(
          'Job status is saved through the backend API.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // INSIGHTS
  Widget _buildStats() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionLabel('WORKSHOP ANALYTICS'),
        const SizedBox(height: 8),
        Text(
          'Performance',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'A quick overview of your workshop activity.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Jobs today',
                '${_allRequests.where((request) => request['apiStatus'] == 'COMPLETED').length}',
                Icons.task_alt_rounded,
                _green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'Rating',
                _stringValue(_mechanic?['rating'], '—'),
                Icons.star_rounded,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Response time',
                '—',
                Icons.timer_outlined,
                _blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'Acceptance',
                '—',
                Icons.thumb_up_alt_outlined,
                _green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _panel(
          title: 'Estimated earnings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Not available', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: _green)),
              const SizedBox(height: 6),
              Text('The current backend does not provide payment or earnings data.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _panel(
          title: 'Recent completed requests',
          child: Column(
            children: _allRequests.where((request) => request['apiStatus'] == 'COMPLETED').isEmpty
                ? [const Text('No completed requests are available from the backend yet.')]
                : _allRequests.where((request) => request['apiStatus'] == 'COMPLETED').take(5).map((request) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _recentService(
                      _stringValue(request['category'], 'Service'),
                      _stringValue(request['vehicle'], 'Vehicle'),
                      'Completed',
                      Icons.task_alt_rounded,
                    ),
                  )).toList(),
          ),
        ),
      ],
    );
  }

  // WORKSHOP PROFILE
  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionLabel('PARTNER ACCOUNT'),
        const SizedBox(height: 8),
        Text(
          _stringValue(_mechanic?['workshop_name'], _stringValue(_mechanic?['name'], 'Workshop profile')),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_blueDark, MechanicTheme.surface],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _blue.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 38,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _stringValue(_mechanic?['workshop_name'], _stringValue(_mechanic?['name'], 'Workshop')),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                _stringValue(_user?['email'], 'Mechanic partner account'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _pill(_stringValue(_mechanic?['status'], 'UNKNOWN'), _blue),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _panel(
          title: 'Workshop information',
          child: Column(
            children: [
              _profileRow('Availability', _isOnline ? 'Available' : 'Unavailable'),
              const Divider(height: 22),
              _profileRow('Experience', '${_mechanic?['experience_years'] ?? _mechanic?['experience'] ?? '—'} years'),
              const Divider(height: 22),
              _profileRow('Phone', _stringValue(_mechanic?['phone_number'])),
              const Divider(height: 22),
              _profileRow('Location', '${_mechanic?['latitude'] ?? '—'}, ${_mechanic?['longitude'] ?? '—'}'),
              const Divider(height: 22),
              _profileRow('Vehicle types', _stringValue(_mechanic?['supported_vehicle_types'])),
              const Divider(height: 22),
              _profileRow('Services', '${_services.length} registered categories'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _panel(
          title: 'Service specialties',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _blue.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  service['name']!,
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, color: _red),
          label: const Text(
            'Sign out',
            style: TextStyle(color: _red),
          ),
        ),
      ],
    );
  }

  // SHARED COMPONENTS
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _blue,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detailLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: MechanicTheme.textSecondary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MechanicTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MechanicTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MechanicTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MechanicTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MechanicTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _recentService(
    String title,
    String vehicle,
    String amount,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                vehicle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            color: _green,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(
    IconData icon,
    String title,
    String subtitle, {
    bool padded = false,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padded ? 28 : 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: MechanicTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: _blue),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
