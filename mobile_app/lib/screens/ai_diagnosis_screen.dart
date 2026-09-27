import 'package:flutter/material.dart';
import '../services/ai_service.dart';

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
  final AiService _aiService = AiService();

  late final TextEditingController _symptomController;
  late final TextEditingController _vehicleController;

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _diagnosis;

  @override
  void initState() {
    super.initState();

    _symptomController = TextEditingController(
      text: widget.initialSymptom ?? '',
    );

    _vehicleController = TextEditingController(
      text: widget.initialVehicleType ?? 'Car',
    );
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _diagnose() async {
    final symptom = _symptomController.text.trim();
    final vehicle = _vehicleController.text.trim();

    if (symptom.isEmpty) {
      setState(() {
        _error = 'Please describe the vehicle problem first.';
        _diagnosis = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _diagnosis = null;
    });

    try {
      final result = await _aiService.diagnoseSymptoms(
        symptomDescription: symptom,
        vehicleType: vehicle.isEmpty ? null : vehicle,
      );

      if (!mounted) return;

      setState(() {
        _diagnosis = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade800;
      case 'HIGH':
        return Colors.red.shade600;
      case 'MEDIUM':
        return Colors.orange.shade700;
      case 'LOW':
        return Colors.green.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _bulletList(List<dynamic> items) {
    if (items.isEmpty) {
      return const Text(
        'No additional information available.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.circle, size: 6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.toString(),
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _statusChip({
    required String label,
    required bool value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: value
              ? Colors.orange.shade50
              : Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? Colors.orange.shade200
                : Colors.green.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: value
                  ? Colors.orange.shade800
                  : Colors.green.shade700,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value ? 'YES' : 'NO',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: value
                    ? Colors.orange.shade900
                    : Colors.green.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosis() {
    final data = _diagnosis!;

    final severity =
        data['severity']?.toString() ?? 'UNKNOWN';

    final category =
        data['suggested_category']?.toString() ??
            'General Repair';

    final confidence =
        data['confidence']?.toString() ?? '0';

    final dtcs =
        (data['detected_dtcs'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Main result header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade700,
                Colors.indigo.shade500,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'AI Diagnosis Result',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                data['problem_understood']?.toString() ??
                    'Problem analysis completed.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Severity / category / confidence
        Row(
          children: [
            Expanded(
              child: _smallMetric(
                'CATEGORY',
                category,
                Icons.build,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallMetric(
                'SEVERITY',
                severity,
                Icons.warning_amber_rounded,
                valueColor: _severityColor(severity),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallMetric(
                'CONFIDENCE',
                '$confidence%',
                Icons.analytics,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _infoCard(
          icon: Icons.search,
          title: 'Diagnosis',
          child: Text(
            data['diagnosis']?.toString() ??
                'No diagnosis information available.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),

        _infoCard(
          icon: Icons.warning_amber_rounded,
          title: 'Possible Causes',
          child: _bulletList(
            (data['possible_causes'] as List<dynamic>?) ?? [],
          ),
        ),

        _infoCard(
          icon: Icons.health_and_safety,
          title: 'Safety Advice',
          child: _bulletList(
            (data['safety_advice'] as List<dynamic>?) ?? [],
          ),
        ),

        _infoCard(
          icon: Icons.recommend,
          title: 'Recommended Action',
          child: Text(
            data['recommended_action']?.toString() ??
                'Professional inspection is recommended.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Roadside / towing
        Row(
          children: [
            _statusChip(
              label: 'Roadside Assistance',
              value: data['roadside_assistance_required'] == true,
              icon: Icons.car_repair,
            ),
            const SizedBox(width: 12),
            _statusChip(
              label: 'Towing Recommended',
              value: data['towing_recommended'] == true,
              icon: Icons.local_shipping,
            ),
          ],
        ),

        const SizedBox(height: 14),

        // DTC section
        _infoCard(
          icon: Icons.memory,
          title: 'Diagnostic Trouble Codes',
          child: dtcs.isEmpty
              ? const Text(
                  'No directly applicable DTC was identified.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Colors.grey,
                  ),
                )
              : Column(
                  children: dtcs.map((dtc) {
                    final code =
                        dtc['code']?.toString() ?? 'Unknown';

                    final description =
                        dtc['description']?.toString() ?? '';

                    final dtcSeverity =
                        dtc['severity']?.toString() ?? '';

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  code,
                                  style: TextStyle(
                                    color: Colors.indigo.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                dtcSeverity,
                                style: TextStyle(
                                  color:
                                      _severityColor(dtcSeverity),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        // Summary
        _infoCard(
          icon: Icons.summarize,
          title: 'Summary',
          child: Text(
            data['summary']?.toString() ??
                'Diagnosis completed.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Find assistance button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, data);
            },
            icon: const Icon(Icons.location_on),
            label: const Text(
              'Find Nearby Assistance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 25),
      ],
    );
  }

  Widget _smallMetric(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'AI Vehicle Diagnosis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Describe your vehicle problem',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Our AI will analyze the symptoms and suggest the appropriate roadside assistance.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _vehicleController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  hintText: 'Car, SUV, Van, Bike...',
                  prefixIcon: const Icon(Icons.directions_car),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _symptomController,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'What problem are you experiencing?',
                  hintText:
                      'Example: My engine is shaking badly and losing power...',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 75),
                    child: Icon(Icons.report_problem_outlined),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _diagnose,
                  icon: _loading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _loading
                        ? 'Analyzing Problem...'
                        : 'Analyze Problem with AI',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (_loading) ...[
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'AI is analyzing your vehicle symptoms...',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              if (_diagnosis != null) _buildDiagnosis(),
            ],
          ),
        ),
      ),
    );
  }
}