import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../auth/auth_service.dart';
import 'certificate_model.dart';
import 'certificate_service.dart';

class CertificateRequestForm extends StatefulWidget {
  final VoidCallback onSubmitted;
  final TabController tabController;

  const CertificateRequestForm({
    super.key,
    required this.onSubmitted,
    required this.tabController,
  });

  @override
  State<CertificateRequestForm> createState() => _CertificateRequestFormState();
}

class _CertificateRequestFormState extends State<CertificateRequestForm> {
  final CertificateService _certificateService = CertificateService();

  // Form State
  final _formKey = GlobalKey<FormState>();
  CertificateType _selectedType = CertificateType.NIHIL_OBSTAT;
  bool _isSubmitting = false;

  late final ScrollController _scrollController;

  // Dynamic controllers and custom values map
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

  TextEditingController _getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();
      _prefillField(key);
    }
    return _controllers[key]!;
  }

  void _prefillField(String key) {
    final user = AuthService().currentUser;
    if (user == null) return;

    final controller = _controllers[key];
    if (controller == null) return;

    final isMale = user.gender?.toUpperCase() == 'MALE';

    switch (key) {
      // Nihil Obstat
      case 'no_issuing_parish':
        controller.text = user.churchName;
        break;
      case 'no_issuing_diocese':
        controller.text = user.location;
        break;
      case 'no_groom_name':
        if (isMale) controller.text = user.name;
        break;
      case 'no_groom_address':
        if (isMale && user.permanentAddress != null) {
          controller.text = user.permanentAddress!;
        }
        break;
      case 'no_groom_parish':
        if (isMale) controller.text = user.churchName;
        break;
      case 'no_groom_diocese':
        if (isMale) controller.text = user.location;
        break;
      case 'no_bride_name':
        if (!isMale) controller.text = user.name;
        break;
      case 'no_bride_address':
        if (!isMale && user.permanentAddress != null) {
          controller.text = user.permanentAddress!;
        }
        break;
      case 'no_bride_parish':
        if (!isMale) controller.text = user.churchName;
        break;
      case 'no_bride_diocese':
        if (!isMale) controller.text = user.location;
        break;

      // Baptism
      case 'bap_name':
        controller.text = user.name;
        break;
      case 'bap_issuing_diocese':
        controller.text = user.location;
        break;
      case 'bap_pob':
        controller.text = user.location;
        break;
      case 'bap_place':
        controller.text = user.churchName;
        break;
      case 'bap_residence':
        if (user.permanentAddress != null) {
          controller.text = user.permanentAddress!;
        }
        break;

      // Marriage Preparation
      case 'prep_name':
        controller.text = user.name;
        break;
      case 'prep_home_parish':
        controller.text = user.churchName;
        break;
      case 'prep_diocese_name':
        controller.text = user.location;
        break;
      case 'prep_target_center':
        controller.text = 'Family Apostolate Centre, Vlangamuri';
        break;

      // Marriage
      case 'mar_issuing_diocese':
        controller.text = user.location;
        break;
      case 'mar_groom_name':
        if (isMale) controller.text = user.name;
        break;
      case 'mar_groom_address':
        if (isMale && user.permanentAddress != null) {
          controller.text = user.permanentAddress!;
        }
        break;
      case 'mar_groom_parish':
        if (isMale) controller.text = user.churchName;
        break;
      case 'mar_bride_name':
        if (!isMale) controller.text = user.name;
        break;
      case 'mar_bride_address':
        if (!isMale && user.permanentAddress != null) {
          controller.text = user.permanentAddress!;
        }
        break;
      case 'mar_bride_parish':
        if (!isMale) controller.text = user.churchName;
        break;
    }
  }

  void _prefillAllFormData() {
    final user = AuthService().currentUser;
    if (user == null) return;

    final isMale = user.gender?.toUpperCase() == 'MALE';
    final userDob = user.dob != null ? DateTime.tryParse(user.dob!) : null;

    if (userDob != null) {
      if (isMale) {
        _formData['no_groom_dob'] ??= userDob;
        _formData['mar_groom_dob'] ??= userDob;
      } else {
        _formData['no_bride_dob'] ??= userDob;
        _formData['mar_bride_dob'] ??= userDob;
      }
      _formData['bap_dob'] ??= userDob;
      _formData['prep_dob'] ??= userDob;
    }

    if (user.gender != null) {
      final genderVal = user.gender!.toUpperCase();
      _formData['bap_gender'] ??= genderVal;
      _formData['prep_gender'] ??= genderVal;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _resetForm() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    setState(() {
      _formData.clear();
    });
  }

  Future<void> _submitRequest(AppLocalizations loc) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> details = {};

      switch (_selectedType) {
        case CertificateType.NIHIL_OBSTAT:
          details['issuingParish'] =
              _getController('no_issuing_parish').text.trim();
          details['issuingDiocese'] =
              _getController('no_issuing_diocese').text.trim();
          details['permissionType'] =
              _formData['no_permission_type'] ?? 'PUBLISH_BANNS_MARRIAGE';

          details['groomName'] = _getController('no_groom_name').text.trim();
          if (_formData['no_groom_dob'] != null) {
            details['groomDob'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['no_groom_dob']);
          }
          if (_formData['no_groom_bapt_date'] != null) {
            details['groomBaptismDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['no_groom_bapt_date']);
          }
          details['groomFather'] =
              _getController('no_groom_father').text.trim();
          details['groomMother'] =
              _getController('no_groom_mother').text.trim();
          details['groomAddress'] =
              _getController('no_groom_address').text.trim();
          details['groomParish'] =
              _getController('no_groom_parish').text.trim();
          details['groomDiocese'] =
              _getController('no_groom_diocese').text.trim();

          details['brideName'] = _getController('no_bride_name').text.trim();
          if (_formData['no_bride_dob'] != null) {
            details['brideDob'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['no_bride_dob']);
          }
          if (_formData['no_bride_bapt_date'] != null) {
            details['brideBaptismDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['no_bride_bapt_date']);
          }
          details['brideFather'] =
              _getController('no_bride_father').text.trim();
          details['brideMother'] =
              _getController('no_bride_mother').text.trim();
          details['brideAddress'] =
              _getController('no_bride_address').text.trim();
          details['brideParish'] =
              _getController('no_bride_parish').text.trim();
          details['brideDiocese'] =
              _getController('no_bride_diocese').text.trim();

          details['impediments'] = _getController('no_impediments').text.trim();
          break;

        case CertificateType.BAPTISM:
          details['name'] = _getController('bap_name').text.trim();
          details['gender'] = _formData['bap_gender'] ?? 'MALE';
          if (_formData['bap_dob'] != null) {
            details['dob'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['bap_dob']);
          }
          details['placeOfBirth'] = _getController('bap_pob').text.trim();
          if (_formData['bap_date'] != null) {
            details['dateOfBaptism'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['bap_date']);
          }
          details['placeOfBaptism'] = _getController('bap_place').text.trim();
          details['fatherName'] = _getController('bap_father').text.trim();
          details['motherName'] = _getController('bap_mother').text.trim();
          details['permanentResidence'] =
              _getController('bap_residence').text.trim();
          details['godfatherName'] =
              _getController('bap_godfather').text.trim();
          details['godmotherName'] =
              _getController('bap_godmother').text.trim();
          details['issuingDiocese'] =
              _getController('bap_issuing_diocese').text.trim();
          details['ministerOfBaptism'] =
              _getController('bap_minister').text.trim();
          details['registryBook'] =
              _getController('bap_registry_book').text.trim();
          break;

        case CertificateType.MARRIAGE_PREPARATION:
          details['targetCenter'] =
              _getController('prep_target_center').text.trim();
          details['name'] = _getController('prep_candidate_name').text.trim();
          details['gender'] = _formData['prep_gender'] ?? 'MALE';
          details['parentName'] =
              _getController('prep_parent_name').text.trim();
          details['homeParish'] =
              _getController('prep_home_parish').text.trim();
          details['substationName'] =
              _getController('prep_substation').text.trim();
          details['foranateArea'] = _getController('prep_foranate').text.trim();
          details['dioceseName'] = _getController('prep_diocese').text.trim();
          details['courseCategory'] =
              _getController('prep_course_category').text.trim();
          break;

        case CertificateType.MARRIAGE:
          details['issuingDiocese'] =
              _getController('mar_issuing_diocese').text.trim();
          details['locationOfMarriage'] =
              _getController('mar_location').text.trim();
          details['substationName'] =
              _getController('mar_substation').text.trim();
          if (_formData['mar_date'] != null) {
            details['marriageDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['mar_date']);
          }
          details['officiatingPriest'] =
              _getController('mar_officiating_priest').text.trim();

          // Groom Block
          details['groomName'] = _getController('mar_groom_name').text.trim();
          details['groomFather'] =
              _getController('mar_groom_father').text.trim();
          details['groomMother'] =
              _getController('mar_groom_mother').text.trim();
          details['groomParish'] =
              _getController('mar_groom_parish').text.trim();
          details['groomPob'] = _getController('mar_groom_pob').text.trim();
          if (_formData['mar_groom_dob'] != null) {
            details['groomDob'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['mar_groom_dob']);
          }
          details['groomPlaceBaptism'] =
              _getController('mar_groom_place_bapt').text.trim();
          if (_formData['mar_groom_bapt_date'] != null) {
            details['groomBaptismDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['mar_groom_bapt_date']);
          }
          details['groomAddress'] =
              _getController('mar_groom_address').text.trim();

          // Bride Block
          details['brideName'] = _getController('mar_bride_name').text.trim();
          details['brideFather'] =
              _getController('mar_bride_father').text.trim();
          details['brideMother'] =
              _getController('mar_bride_mother').text.trim();
          details['brideParish'] =
              _getController('mar_bride_parish').text.trim();
          details['bridePob'] = _getController('mar_bride_pob').text.trim();
          if (_formData['mar_bride_dob'] != null) {
            details['brideDob'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['mar_bride_dob']);
          }
          details['bridePlaceBaptism'] =
              _getController('mar_bride_place_bapt').text.trim();
          if (_formData['mar_bride_bapt_date'] != null) {
            details['brideBaptismDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(_formData['mar_bride_bapt_date']);
          }
          details['brideAddress'] =
              _getController('mar_bride_address').text.trim();

          // Witness 1
          details['witness1Name'] = _getController('mar_w1_name').text.trim();
          details['witness1Parish'] =
              _getController('mar_w1_parish').text.trim();
          details['witness1Address'] =
              _getController('mar_w1_address').text.trim();

          // Witness 2
          details['witness2Name'] = _getController('mar_w2_name').text.trim();
          details['witness2Parish'] =
              _getController('mar_w2_parish').text.trim();
          details['witness2Address'] =
              _getController('mar_w2_address').text.trim();
          break;
      }

      await _certificateService.createCertificateRequest(
        type: _selectedType.name,
        details: details,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.requestSuccess,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _resetForm();
        widget.onSubmitted();
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0, // 0.0 is the very top of the scrollable view
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    return await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D3A99),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  String _getTypeDisplayName(CertificateType type, AppLocalizations loc) {
    switch (type) {
      case CertificateType.BAPTISM:
        return loc.baptism;
      case CertificateType.MARRIAGE:
        return loc.marriage;
      case CertificateType.MARRIAGE_PREPARATION:
        return loc.marriagePreparation;
      case CertificateType.NIHIL_OBSTAT:
        return loc.nihilObstat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.requestCertificate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D3A99),
                  ),
                ),
                const SizedBox(height: 24),
                // Dropdown for certificate type
                Text(
                  loc.certificateType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.grey[50],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CertificateType>(
                      value: _selectedType,
                      isExpanded: true,
                      dropdownColor: theme.cardColor,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF5D3A99),
                      ),
                      onChanged: (CertificateType? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedType = newValue;
                            _resetForm();
                          });
                        }
                      },
                      items:
                          CertificateType.values
                              .map<DropdownMenuItem<CertificateType>>((
                                CertificateType value,
                              ) {
                                return DropdownMenuItem<CertificateType>(
                                  value: value,
                                  child: Text(
                                    _getTypeDisplayName(value, loc),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                // Dynamic Fields based on Selected Certificate Type
                ..._buildDynamicFormFields(loc, theme, isDark),
                const SizedBox(height: 32),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5D3A99), Color(0xFF7B1FA2)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed:
                          _isSubmitting ? null : () => _submitRequest(loc),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                              : Text(
                                loc.submitRequest.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF5D3A99),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D3A99),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  List<Widget> _buildDynamicFormFields(
    AppLocalizations loc,
    ThemeData theme,
    bool isDark,
  ) {
    _prefillAllFormData();
    switch (_selectedType) {
      case CertificateType.NIHIL_OBSTAT:
        return [
          _buildFormSectionTitle(loc.clearanceForm),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('no_issuing_parish'),
                label: loc.issuingParish,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_issuing_diocese'),
                label: loc.issuingDiocese,
                icon: Icons.location_city_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle(loc.permissionType),
          _buildSectionCard(
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                value:
                    _formData['no_permission_type'] ?? 'PUBLISH_BANNS_MARRIAGE',
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.verified_outlined,
                    color: Color(0xFF5D3A99),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                dropdownColor: theme.cardColor,
                onChanged: (val) {
                  setState(() {
                    _formData['no_permission_type'] = val;
                  });
                },
                items: [
                  DropdownMenuItem(
                    value: 'ASSIST_AT_ENGAGEMENT',
                    child: Text(
                      loc.assistAtEngagement,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'PUBLISH_BANNS_MARRIAGE',
                    child: Text(
                      loc.publishBannsMarriage,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ASSIST_AT_THE_MARRIAGE',
                    child: Text(
                      loc.assistAtTheMarriage,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),

          _buildFormSectionTitle(loc.groomDetails),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('no_groom_name'),
                label: loc.name,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dob,
                selectedDate: _formData['no_groom_dob'],
                onTap: () async {
                  final date = await _pickDate(
                    context,
                    _formData['no_groom_dob'],
                  );
                  if (date != null)
                    setState(() => _formData['no_groom_dob'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dateOfBaptism,
                selectedDate: _formData['no_groom_bapt_date'],
                onTap: () async {
                  final date = await _pickDate(
                    context,
                    _formData['no_groom_bapt_date'],
                  );
                  if (date != null)
                    setState(() => _formData['no_groom_bapt_date'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_groom_father'),
                label: loc.fatherName,
                icon: Icons.person,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_groom_mother'),
                label: loc.motherName,
                icon: Icons.person_3_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_groom_address'),
                label: loc.homeAddress,
                icon: Icons.home_outlined,
                maxLines: 2,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_groom_parish'),
                label: loc.currentParish,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_groom_diocese'),
                label: loc.currentDiocese,
                icon: Icons.location_city_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle(loc.brideDetails),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('no_bride_name'),
                label: loc.name,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dob,
                selectedDate: _formData['no_bride_dob'],
                onTap: () async {
                  final date = await _pickDate(
                    context,
                    _formData['no_bride_dob'],
                  );
                  if (date != null)
                    setState(() => _formData['no_bride_dob'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dateOfBaptism,
                selectedDate: _formData['no_bride_bapt_date'],
                onTap: () async {
                  final date = await _pickDate(
                    context,
                    _formData['no_bride_bapt_date'],
                  );
                  if (date != null)
                    setState(() => _formData['no_bride_bapt_date'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_bride_father'),
                label: loc.fatherName,
                icon: Icons.person,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_bride_mother'),
                label: loc.motherName,
                icon: Icons.person_3_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_bride_address'),
                label: loc.homeAddress,
                icon: Icons.home_outlined,
                maxLines: 2,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_bride_parish'),
                label: loc.currentParish,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('no_bride_diocese'),
                label: loc.currentDiocese,
                icon: Icons.location_city_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle(loc.impedimentsLabel),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('no_impediments'),
                label: loc.impediments,
                icon: Icons.warning_amber_rounded,
                maxLines: 3,
              ),
            ],
          ),
        ];

      case CertificateType.BAPTISM:
        return [
          _buildFormSectionTitle(loc.details),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('bap_name'),
                label: loc.name,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildGenderDropdown(loc, isDark),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dob,
                selectedDate: _formData['bap_dob'],
                onTap: () async {
                  final date = await _pickDate(context, _formData['bap_dob']);
                  if (date != null) setState(() => _formData['bap_dob'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('bap_pob'),
                label: loc.placeOfBirth,
                icon: Icons.location_on_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dateOfBaptism,
                selectedDate: _formData['bap_date'],
                onTap: () async {
                  final date = await _pickDate(context, _formData['bap_date']);
                  if (date != null)
                    setState(() => _formData['bap_date'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('bap_place'),
                label: loc.placeOfBaptism,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle('${loc.fatherName} & ${loc.motherName}'),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('bap_father'),
                label: loc.fatherName,
                icon: Icons.person,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('bap_mother'),
                label: loc.motherName,
                icon: Icons.person_3_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('bap_residence'),
                label: loc.homeAddress,
                icon: Icons.home_outlined,
                maxLines: 2,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('bap_godfather'),
                label: loc.godfatherName,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('bap_godmother'),
                label: loc.godmotherName,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle('Ecclesiastical details'),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('bap_issuing_diocese'),
                label: loc.issuingDiocese,
                icon: Icons.location_city_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('bap_minister'),
                label: loc.ministerOfBaptism,
                icon: Icons.assignment_ind_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('bap_registry_book'),
                label: '${loc.registryBook} (${loc.keptAt})',
                icon: Icons.menu_book_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),
        ];

      case CertificateType.MARRIAGE_PREPARATION:
        if (_getController('prep_target_center').text.isEmpty) {
          _getController('prep_target_center').text =
              'Family Apostolate Centre, Vlangamuri';
        }
        return [
          _buildFormSectionTitle(loc.marriagePreparation),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('prep_target_center'),
                label: loc.targetCenter,
                icon: Icons.business_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('prep_course_category'),
                label: loc.courseCategory,
                icon: Icons.calendar_today_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle(loc.details),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('prep_candidate_name'),
                label: loc.name,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildGenderDropdown(loc, isDark, stateKey: 'prep_gender'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('prep_parent_name'),
                label:
                    '${loc.fatherName} / ${loc.motherName} (Son/Daughter of...)',
                icon: Icons.people_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle('Home Parish Registry'),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('prep_home_parish'),
                label: loc.issuingParish,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('prep_substation'),
                label: loc.substationName,
                icon: Icons.church_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('prep_foranate'),
                label: loc.foranateArea,
                icon: Icons.map_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('prep_diocese'),
                label: loc.issuingDiocese,
                icon: Icons.location_city_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),
        ];

      case CertificateType.MARRIAGE:
        return [
          _buildFormSectionTitle(loc.marriageLocation),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('mar_issuing_diocese'),
                label: loc.issuingDiocese,
                icon: Icons.location_city_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_location'),
                label: loc.marriageLocation,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_substation'),
                label: loc.substationName,
                icon: Icons.church_outlined,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.marriageDate,
                selectedDate: _formData['mar_date'],
                onTap: () async {
                  final date = await _pickDate(context, _formData['mar_date']);
                  if (date != null)
                    setState(() => _formData['mar_date'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_officiating_priest'),
                label: loc.officiatingPriest,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle(loc.groomDetails),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('mar_groom_name'),
                label: loc.name,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_groom_father'),
                label: loc.fatherName,
                icon: Icons.person,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_groom_mother'),
                label: loc.motherName,
                icon: Icons.person_3_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_groom_parish'),
                label: loc.currentParish,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_groom_pob'),
                label: loc.placeOfBirth,
                icon: Icons.location_on_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dob,
                selectedDate: _formData['mar_groom_dob'],
                onTap: () async {
                  final date = await _pickDate(
                    context,
                    _formData['mar_groom_dob'],
                  );
                  if (date != null)
                    setState(() => _formData['mar_groom_dob'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_groom_place_bapt'),
                label: loc.placeOfBaptism,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dateOfBaptism,
                selectedDate: _formData['mar_groom_bapt_date'],
                onTap: () async {
                  final date = await _pickDate(
                    context,
                    _formData['mar_groom_bapt_date'],
                  );
                  if (date != null)
                    setState(() => _formData['mar_groom_bapt_date'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_groom_address'),
                label: loc.homeAddress,
                icon: Icons.home_outlined,
                maxLines: 2,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle(loc.brideDetails),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('mar_bride_name'),
                label: loc.name,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_bride_father'),
                label: loc.fatherName,
                icon: Icons.person,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_bride_mother'),
                label: loc.motherName,
                icon: Icons.person_3_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_bride_parish'),
                label: loc.currentParish,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_bride_pob'),
                label: loc.placeOfBirth,
                icon: Icons.location_on_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dob,
                selectedDate: _formData['mar_bride_dob'],
                onTap: () async {
                  final date = await _pickDate(
                    context,
                    _formData['mar_bride_dob'],
                  );
                  if (date != null)
                    setState(() => _formData['mar_bride_dob'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_bride_place_bapt'),
                label: loc.placeOfBaptism,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: loc.dateOfBaptism,
                selectedDate: _formData['mar_bride_bapt_date'],
                onTap: () async {
                  final date = await _pickDate(
                    context,
                    _formData['mar_bride_bapt_date'],
                  );
                  if (date != null)
                    setState(() => _formData['mar_bride_bapt_date'] = date);
                },
                loc: loc,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_bride_address'),
                label: loc.homeAddress,
                icon: Icons.home_outlined,
                maxLines: 2,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle(loc.witness1),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('mar_w1_name'),
                label: loc.witnessName,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_w1_parish'),
                label: loc.witnessParish,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_w1_address'),
                label: loc.witnessAddress,
                icon: Icons.home_outlined,
                maxLines: 2,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),

          _buildFormSectionTitle(loc.witness2),
          _buildSectionCard(
            children: [
              _buildTextField(
                controller: _getController('mar_w2_name'),
                label: loc.witnessName,
                icon: Icons.person_outline,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_w2_parish'),
                label: loc.witnessParish,
                icon: Icons.church_outlined,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _getController('mar_w2_address'),
                label: loc.witnessAddress,
                icon: Icons.home_outlined,
                maxLines: 2,
                validator:
                    (val) =>
                        val == null || val.isEmpty ? loc.fieldRequired : null,
              ),
            ],
          ),
        ];
    }
    return [];
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF5D3A99), size: 22),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF5D3A99), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(
    AppLocalizations loc,
    bool isDark, {
    String stateKey = 'bap_gender',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.gender,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _formData[stateKey] ?? 'MALE',
              isExpanded: true,
              dropdownColor: Theme.of(context).cardColor,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF5D3A99),
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _formData[stateKey] = newValue;
                  });
                }
              },
              items: [
                DropdownMenuItem(value: 'MALE', child: Text(loc.male)),
                DropdownMenuItem(value: 'FEMALE', child: Text(loc.female)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required AppLocalizations loc,
    required bool isDark,
  }) {
    final dateStr =
        selectedDate == null
            ? loc.selectDate
            : DateFormat('MMMM dd, yyyy').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF5D3A99),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: selectedDate == null ? Colors.grey : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
