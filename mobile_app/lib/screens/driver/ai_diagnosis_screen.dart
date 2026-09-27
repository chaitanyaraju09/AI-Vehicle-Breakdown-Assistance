import 'package:flutter/material.dart';

import '../../services/ai_service.dart';
import 'mechanic_match_screen.dart';

class AiDiagnosisScreen extends StatefulWidget {
  final String? initialVehicleType;
  final String? initialSymptom;

  const AiDiagnosisScreen({
    super.key,
    this.initialVehicleType,
    this.initialSymptom,
  });

  @override
  State<AiDiagnosisScreen> createState() => _AiDiagnosisScreenState();
}

class _AiDiagnosisScreenState extends State<AiDiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomController = TextEditingController();
  final AiService _aiService = AiService();

  String _vehicleType = 'Car';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  final List<String> _vehicleTypes = [
    'Car',
    'Bike',
    'Scooter',
    'SUV',
    'Van',
    'Pickup',
    'Truck',
    'Bus',
    'Auto Rickshaw',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialVehicleType != null &&
        widget.initialVehicleType!.trim().isNotEmpty) {
      final initial = widget.initialVehicleType!.trim();

      if (_vehicleTypes.contains(initial)) {
        _vehicleType = initial;
      }
    }

    if (widget.initialSymptom != null) {
      _symptomController.text = widget.initialSymptom!;
    }
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _diagnose() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _aiService.diagnoseSymptoms(
        symptomDescription: _symptomController.text.trim(),
        vehicleType: _vehicleType,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade900;
      case 'HIGH':
        return Colors.red.shade700;
      case 'MEDIUM':
      case 'MODERATE':
        return Colors.orange.shade800;
      case 'LOW':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  String _stringValue(
    String key, [
    String fallback = 'Not available',
  ]) {
    final value = _result?[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  List<String> _stringList(String key) {
    final value = _result?[key];

    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return [];
  }

  bool _boolValue(String key) {
    final value = _result?[key];

    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Breakdown Diagnosis'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_rounded),
                  SizedBox(width: 10),
                  Text(
                    'AI Vehicle Diagnosis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Describe your vehicle problem and let the AI analyze the symptoms.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car_rounded),
                ),
                items: _vehicleTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _vehicleType = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _symptomController,
                maxLines: 5,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Describe the problem',
                  hintText:
                      'Example: My bike is not starting and the battery light is on.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 70),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the vehicle problem.';
                  }

                  if (value.trim().length < 5) {
                    return 'Please provide a little more detail.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _diagnose,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isLoading
                        ? 'Analyzing Problem...'
                        : 'Analyze with AI',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(
          color: Colors.red.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final category = _stringValue(
      'suggested_category',
      'General Repair',
    );

    final severity = _stringValue(
      'severity',
      'UNKNOWN',
    );

    final confidence = _result?['confidence'];

    final diagnosis = _stringValue(
      'diagnosis',
      'No detailed diagnosis available.',
    );

    final problemUnderstood = _stringValue(
      'problem_understood',
      'The problem could not be clearly determined.',
    );

    final possibleCauses = _stringList('possible_causes');
    final safetyAdvice = _stringList('safety_advice');

    final recommendedAction = _stringValue(
      'recommended_action',
      'Consult a qualified mechanic.',
    );

    final summary = _stringValue(
      'summary',
      '',
    );

    final roadsideRequired =
        _boolValue('roadside_assistance_required');

    final towingRecommended =
        _boolValue('towing_recommended');

    final dtcs = _result?['detected_dtcs'] is List
        ? (_result!['detected_dtcs'] as List)
        : <dynamic>[];

    final severityColor = _severityColor(severity);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.health_and_safety_rounded),
                SizedBox(width: 10),
                Text(
                  'Diagnosis Result',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(
                  Icons.category_rounded,
                  category,
                ),
                _severityChip(
                  severity,
                  severityColor,
                ),
              ],
            ),
            if (confidence != null) ...[
              const SizedBox(height: 12),
              _buildConfidence(confidence),
            ],
            const Divider(height: 28),
            _section(
              icon: Icons.search_rounded,
              title: 'Problem Understood',
              child: Text(problemUnderstood),
            ),
            _section(
              icon: Icons.medical_information_outlined,
              title: 'Diagnosis',
              child: Text(diagnosis),
            ),
            if (possibleCauses.isNotEmpty)
              _buildBulletSection(
                title: 'Possible Causes',
                icon: Icons.list_alt_rounded,
                items: possibleCauses,
              ),
            if (safetyAdvice.isNotEmpty)
              _buildSafetySection(safetyAdvice),
            _section(
              icon: Icons.build_circle_outlined,
              title: 'Recommended Action',
              child: Text(recommendedAction),
            ),
            _buildAssistanceStatus(
              roadsideRequired: roadsideRequired,
              towingRecommended: towingRecommended,
            ),
            if (dtcs.isNotEmpty)
              _buildDtcSection(dtcs),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              _section(
                icon: Icons.summarize_rounded,
                title: 'Summary',
                child: Text(summary),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on_rounded),
                label: const Text(
                  'Find Nearby Assistance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MechanicMatchScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _severityChip(
    String severity,
    Color color,
  ) {
    return Chip(
      avatar: Icon(
        Icons.warning_rounded,
        size: 18,
        color: color,
      ),
      label: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      side: BorderSide(color: color),
    );
  }

  Widget _buildConfidence(dynamic confidence) {
    double value;

    if (confidence is num) {
      value = confidence.toDouble();
    } else {
      value = double.tryParse(
            confidence.toString(),
          ) ??
          0;
    }

    value = value.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI Confidence',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: value / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletSection({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(item),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection(List<String> advice) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(
          color: Colors.amber.shade400,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade900,
              ),
              const SizedBox(width: 8),
              const Text(
                'Safety Advice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...advice.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(item),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceStatus({
    required bool roadsideRequired,
    required bool towingRecommended,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent_rounded),
              SizedBox(width: 8),
              Text(
                'Assistance Recommendation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  roadsideRequired
                      ? Icons.check_circle
                      : Icons.remove_circle_outline,
                  size: 18,
                ),
                label: Text(
                  roadsideRequired
                      ? 'Roadside Assistance Required'
                      : 'Roadside Assistance Not Required',
                ),
              ),
              if (towingRecommended)
                const Chip(
                  avatar: Icon(
                    Icons.local_shipping_rounded,
                    size: 18,
                  ),
                  label: Text('Towing Recommended'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDtcSection(List<dynamic> dtcs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Diagnostic Trouble Codes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...dtcs.map(
            (dtc) {
              if (dtc is! Map) {
                return Text(dtc.toString());
              }

              final code =
                  dtc['code']?.toString() ?? 'Unknown';

              final description =
                  dtc['description']?.toString() ?? '';

              final severity =
                  dtc['severity']?.toString() ?? '';

              final causes =
                  dtc['possible_causes']?.toString() ?? '';

              final action =
                  dtc['recommended_action']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (severity.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              severity.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _severityColor(severity),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (description.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(description),
                        ),
                      if (causes.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Text(
                            'Possible causes: $causes',
                          ),
                        ),
                      if (action.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8),
                          child: Text(
                            'Recommended action: $action',
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}