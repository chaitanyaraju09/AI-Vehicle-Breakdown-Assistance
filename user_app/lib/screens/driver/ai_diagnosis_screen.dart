import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
        return AppColors.danger;
      case 'HIGH':
        return const Color(0xFFFF6B5E);
      case 'MEDIUM':
      case 'MODERATE':
        return AppColors.warning;
      case 'LOW':
        return AppColors.success;
      default:
        return AppColors.primaryLight;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Breakdown Diagnosis'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.backgroundSecondary,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputCard(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 18),
                  _buildResultCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.cyan,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Vehicle Diagnosis',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Intelligent roadside analysis',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text(
              'Describe what is happening with your vehicle.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              dropdownColor: AppColors.surfaceElevated,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primaryLight,
                ),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.45,
              ),
              decoration: InputDecoration(
                labelText: 'Describe the problem',
                labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                ),
                hintText:
                    'Example: My engine is shaking and I am losing power.',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 70),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppColors.primaryLight,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
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
              height: 54,
              child: FilledButton.icon(
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
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isLoading
                      ? 'Analyzing Problem...'
                      : 'Analyze with AI',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.4,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResultHeader(
          category: category,
          severity: severity,
          severityColor: severityColor,
        ),

        const SizedBox(height: 14),

        if (confidence != null) _buildConfidenceCard(confidence),

        if (confidence != null) const SizedBox(height: 14),

        _buildContentCard(
          icon: Icons.search_rounded,
          title: 'Problem Understood',
          child: Text(
            problemUnderstood,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ),

        const SizedBox(height: 12),

        _buildContentCard(
          icon: Icons.medical_information_outlined,
          title: 'Diagnosis',
          child: Text(
            diagnosis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ),

        if (possibleCauses.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildBulletCard(
            title: 'Possible Causes',
            icon: Icons.list_alt_rounded,
            items: possibleCauses,
          ),
        ],

        if (safetyAdvice.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSafetyCard(safetyAdvice),
        ],

        const SizedBox(height: 12),

        _buildContentCard(
          icon: Icons.build_circle_outlined,
          title: 'Recommended Action',
          child: Text(
            recommendedAction,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ),

        const SizedBox(height: 12),

        _buildAssistanceStatus(
          roadsideRequired: roadsideRequired,
          towingRecommended: towingRecommended,
        ),

        if (dtcs.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDtcCard(dtcs),
        ],

        if (summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildContentCard(
            icon: Icons.summarize_rounded,
            title: 'Summary',
            child: Text(
              summary,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        SizedBox(
          height: 54,
          child: FilledButton.icon(
            icon: const Icon(Icons.location_on_rounded),
            label: const Text(
              'Find Nearby Assistance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MechanicMatchScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultHeader({
    required String category,
    required String severity,
    required Color severityColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18335F),
            Color(0xFF10213B),
            Color(0xFF0D1727),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.cyan,
              ),
              SizedBox(width: 9),
              Text(
                'Diagnosis Result',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _resultBadge(
                  icon: Icons.category_rounded,
                  label: category,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resultBadge(
                  icon: Icons.warning_amber_rounded,
                  label: severity.toUpperCase(),
                  color: severityColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(dynamic confidence) {
    double value;

    if (confidence is num) {
      value = confidence.toDouble();
    } else {
      value = double.tryParse(
            confidence.toString(),
          ) ??
          0;
    }

    value = value.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 19,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Confidence',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletCard({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard(List<String> advice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Safety Advice',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...advice.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
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
    final active = roadsideRequired || towingRecommended;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.success.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: active
                      ? AppColors.primaryLight
                      : AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Assistance Recommendation',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip(
                icon: roadsideRequired
                    ? Icons.check_circle_rounded
                    : Icons.remove_circle_outline_rounded,
                label: roadsideRequired
                    ? 'Roadside Assistance Required'
                    : 'Roadside Assistance Not Required',
                color: roadsideRequired
                    ? AppColors.primaryLight
                    : AppColors.success,
              ),
              if (towingRecommended)
                _statusChip(
                  icon: Icons.local_shipping_rounded,
                  label: 'Towing Recommended',
                  color: AppColors.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDtcCard(List<dynamic> dtcs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.memory_rounded,
                color: AppColors.cyan,
                size: 20,
              ),
              SizedBox(width: 9),
              Text(
                'Diagnostic Trouble Codes',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...dtcs.map(
            (dtc) {
              if (dtc is! Map) {
                return Text(
                  dtc.toString(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                );
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

              final color = _severityColor(severity);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (severity.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (causes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Possible causes: $causes',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (action.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Recommended action: $action',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}