import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import 'certificate_model.dart';
import 'certificate_service.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CertificateService _certificateService = CertificateService();

  late Future<List<CertificateRequest>> _requestsFuture;

  // Priest Filter State
  String _selectedFilter = 'All';

  // Form State
  final _formKey = GlobalKey<FormState>();
  CertificateType _selectedType = CertificateType.NIHIL_OBSTAT;
  bool _isSubmitting = false;

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
    _tabController = TabController(length: 2, vsync: this);
    _refreshRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refreshRequests() {
    setState(() {
      final user = AuthService().currentUser;
      final bool isPriest = user?.role.toLowerCase() == 'priest';
      
      if (isPriest) {
        _requestsFuture = _certificateService.fetchChurchRequests(
          status: _selectedFilter == 'All' ? null : _selectedFilter.toUpperCase(),
        );
      } else {
        _requestsFuture = _certificateService.fetchMyRequests();
      }
    });
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
          details['issuingParish'] = _getController('no_issuing_parish').text.trim();
          details['issuingDiocese'] = _getController('no_issuing_diocese').text.trim();
          details['permissionType'] = _formData['no_permission_type'] ?? 'PUBLISH_BANNS_MARRIAGE';
          
          details['groomName'] = _getController('no_groom_name').text.trim();
          if (_formData['no_groom_dob'] != null) {
            details['groomDob'] = DateFormat('yyyy-MM-dd').format(_formData['no_groom_dob']);
          }
          if (_formData['no_groom_bapt_date'] != null) {
            details['groomBaptismDate'] = DateFormat('yyyy-MM-dd').format(_formData['no_groom_bapt_date']);
          }
          details['groomFather'] = _getController('no_groom_father').text.trim();
          details['groomMother'] = _getController('no_groom_mother').text.trim();
          details['groomAddress'] = _getController('no_groom_address').text.trim();
          details['groomParish'] = _getController('no_groom_parish').text.trim();
          details['groomDiocese'] = _getController('no_groom_diocese').text.trim();

          details['brideName'] = _getController('no_bride_name').text.trim();
          if (_formData['no_bride_dob'] != null) {
            details['brideDob'] = DateFormat('yyyy-MM-dd').format(_formData['no_bride_dob']);
          }
          if (_formData['no_bride_bapt_date'] != null) {
            details['brideBaptismDate'] = DateFormat('yyyy-MM-dd').format(_formData['no_bride_bapt_date']);
          }
          details['brideFather'] = _getController('no_bride_father').text.trim();
          details['brideMother'] = _getController('no_bride_mother').text.trim();
          details['brideAddress'] = _getController('no_bride_address').text.trim();
          details['brideParish'] = _getController('no_bride_parish').text.trim();
          details['brideDiocese'] = _getController('no_bride_diocese').text.trim();
          
          details['impediments'] = _getController('no_impediments').text.trim();
          break;

        case CertificateType.BAPTISM:
          details['name'] = _getController('bap_name').text.trim();
          details['gender'] = _formData['bap_gender'] ?? 'MALE';
          if (_formData['bap_dob'] != null) {
            details['dob'] = DateFormat('yyyy-MM-dd').format(_formData['bap_dob']);
          }
          details['placeOfBirth'] = _getController('bap_pob').text.trim();
          if (_formData['bap_date'] != null) {
            details['dateOfBaptism'] = DateFormat('yyyy-MM-dd').format(_formData['bap_date']);
          }
          details['placeOfBaptism'] = _getController('bap_place').text.trim();
          details['fatherName'] = _getController('bap_father').text.trim();
          details['motherName'] = _getController('bap_mother').text.trim();
          details['permanentResidence'] = _getController('bap_residence').text.trim();
          details['godfatherName'] = _getController('bap_godfather').text.trim();
          details['godmotherName'] = _getController('bap_godmother').text.trim();
          details['issuingDiocese'] = _getController('bap_issuing_diocese').text.trim();
          details['ministerOfBaptism'] = _getController('bap_minister').text.trim();

          details['registryBook'] = _getController('bap_registry_book').text.trim();
          break;



        case CertificateType.MARRIAGE_PREPARATION:
          details['targetCenter'] = _getController('prep_target_center').text.trim();
          details['name'] = _getController('prep_candidate_name').text.trim();
          details['gender'] = _formData['prep_gender'] ?? 'MALE';
          details['parentName'] = _getController('prep_parent_name').text.trim();
          details['homeParish'] = _getController('prep_home_parish').text.trim();
          details['substationName'] = _getController('prep_substation').text.trim();
          details['foranateArea'] = _getController('prep_foranate').text.trim();
          details['dioceseName'] = _getController('prep_diocese').text.trim();
          details['courseCategory'] = _getController('prep_course_category').text.trim();
          break;

        case CertificateType.MARRIAGE:
          details['issuingDiocese'] = _getController('mar_issuing_diocese').text.trim();
          details['locationOfMarriage'] = _getController('mar_location').text.trim();
          details['substationName'] = _getController('mar_substation').text.trim();
          if (_formData['mar_date'] != null) {
            details['marriageDate'] = DateFormat('yyyy-MM-dd').format(_formData['mar_date']);
          }
          details['officiatingPriest'] = _getController('mar_officiating_priest').text.trim();

          // Groom Block
          details['groomName'] = _getController('mar_groom_name').text.trim();
          details['groomFather'] = _getController('mar_groom_father').text.trim();
          details['groomMother'] = _getController('mar_groom_mother').text.trim();
          details['groomParish'] = _getController('mar_groom_parish').text.trim();
          details['groomPob'] = _getController('mar_groom_pob').text.trim();
          if (_formData['mar_groom_dob'] != null) {
            details['groomDob'] = DateFormat('yyyy-MM-dd').format(_formData['mar_groom_dob']);
          }
          details['groomPlaceBaptism'] = _getController('mar_groom_place_bapt').text.trim();
          if (_formData['mar_groom_bapt_date'] != null) {
            details['groomBaptismDate'] = DateFormat('yyyy-MM-dd').format(_formData['mar_groom_bapt_date']);
          }
          details['groomAddress'] = _getController('mar_groom_address').text.trim();

          // Bride Block
          details['brideName'] = _getController('mar_bride_name').text.trim();
          details['brideFather'] = _getController('mar_bride_father').text.trim();
          details['brideMother'] = _getController('mar_bride_mother').text.trim();
          details['brideParish'] = _getController('mar_bride_parish').text.trim();
          details['bridePob'] = _getController('mar_bride_pob').text.trim();
          if (_formData['mar_bride_dob'] != null) {
            details['brideDob'] = DateFormat('yyyy-MM-dd').format(_formData['mar_bride_dob']);
          }
          details['bridePlaceBaptism'] = _getController('mar_bride_place_bapt').text.trim();
          if (_formData['mar_bride_bapt_date'] != null) {
            details['brideBaptismDate'] = DateFormat('yyyy-MM-dd').format(_formData['mar_bride_bapt_date']);
          }
          details['brideAddress'] = _getController('mar_bride_address').text.trim();

          // Witness 1
          details['witness1Name'] = _getController('mar_w1_name').text.trim();
          details['witness1Parish'] = _getController('mar_w1_parish').text.trim();
          details['witness1Address'] = _getController('mar_w1_address').text.trim();

          // Witness 2
          details['witness2Name'] = _getController('mar_w2_name').text.trim();
          details['witness2Parish'] = _getController('mar_w2_parish').text.trim();
          details['witness2Address'] = _getController('mar_w2_address').text.trim();
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
        _refreshRequests();
        _tabController.animateTo(1);
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

  Future<void> _approveRequest(String id, Map<String, dynamic> officialDetails, AppLocalizations loc) async {
    try {
      final message = await _certificateService.approveRequest(id, body: officialDetails);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _refreshRequests();
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
    }
  }

  Future<void> _rejectRequest(String id, String? reason, AppLocalizations loc) async {
    try {
      final message = await _certificateService.rejectRequest(id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _refreshRequests();
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      final navigator = Navigator.of(context);
      Future.microtask(
        () => navigator.pushReplacementNamed(Routes.login),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isPriest = user.role.toLowerCase() == 'priest';

    if (isPriest) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: AppDrawer(user: user),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 130.0,
                pinned: true,
                floating: false,
                backgroundColor: const Color(0xFF5D3A99),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    loc.manageCertificates,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5D3A99), Color(0xFF7B1FA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              _buildFilterBar(loc, theme),
              Expanded(
                child: _buildPriestHistoryTab(loc, theme, isDark),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppDrawer(user: user),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 130.0,
              pinned: true,
              floating: false,
              backgroundColor: const Color(0xFF5D3A99),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 50),
                centerTitle: true,
                title: Text(
                  loc.certificates,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5D3A99), Color(0xFF7B1FA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF5D3A99),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: const Color(0xFF5D3A99),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: loc.requestCertificate),
                      Tab(text: loc.myRequests),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestTab(loc, theme, isDark),
            _buildHistoryTab(loc, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations loc, ThemeData theme) {
    final filters = ["All", "Pending", "Approved", "Rejected"];
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: filters.map((f) {
              final isSelected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      f == "All"
                          ? (loc.all)
                          : (f == "Pending"
                              ? (loc.pending)
                              : (f == "Approved"
                                  ? (loc.approved)
                                  : (loc.rejected))),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedFilter = f;
                      _refreshRequests();
                    });
                  },
                  selectedColor: const Color(0xFF5D3A99),
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPriestHistoryTab(
      AppLocalizations loc, ThemeData theme, bool isDark) {
    return FutureBuilder<List<CertificateRequest>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.red[400], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    loc.errorOccurred,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshRequests,
                    child: const Text('Retry'),
                  )
                ],
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _refreshRequests(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF5D3A99).withValues(alpha: 0.08),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_outlined,
                          color: Color(0xFF5D3A99),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.noPendingCertificates,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshRequests(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _CertificateRequestCard(
                request: req,
                loc: loc,
                theme: theme,
                isDark: isDark,
                isPriest: true,
                onApprove: (officialDetails) => _approveRequest(req.id, officialDetails, loc),
                onReject: (reason) => _rejectRequest(req.id, reason, loc),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestTab(
      AppLocalizations loc, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
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
                    color: isDark
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
                      items: CertificateType.values
                          .map<DropdownMenuItem<CertificateType>>(
                              (CertificateType value) {
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
                      }).toList(),
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
                      onPressed: _isSubmitting ? null : () => _submitRequest(loc),
                      child: _isSubmitting
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
      AppLocalizations loc, ThemeData theme, bool isDark) {
    _prefillAllFormData();
    switch (_selectedType) {
      case CertificateType.NIHIL_OBSTAT:
        return [
          _buildFormSectionTitle(loc.clearanceForm),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('no_issuing_parish'),
              label: loc.issuingParish,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_issuing_diocese'),
              label: loc.issuingDiocese,
              icon: Icons.location_city_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),
          
          _buildFormSectionTitle(loc.permissionType),
          _buildSectionCard(children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _formData['no_permission_type'] ?? 'PUBLISH_BANNS_MARRIAGE',
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.verified_outlined, color: Color(0xFF5D3A99)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
          ]),

          _buildFormSectionTitle(loc.groomDetails),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('no_groom_name'),
              label: loc.name,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dob,
              selectedDate: _formData['no_groom_dob'],
              onTap: () async {
                final date = await _pickDate(context, _formData['no_groom_dob']);
                if (date != null) setState(() => _formData['no_groom_dob'] = date);
              },
              loc: loc,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dateOfBaptism,
              selectedDate: _formData['no_groom_bapt_date'],
              onTap: () async {
                final date = await _pickDate(context, _formData['no_groom_bapt_date']);
                if (date != null) setState(() => _formData['no_groom_bapt_date'] = date);
              },
              loc: loc,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_groom_father'),
              label: loc.fatherName,
              icon: Icons.person,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_groom_mother'),
              label: loc.motherName,
              icon: Icons.person_3_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_groom_address'),
              label: loc.homeAddress,
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_groom_parish'),
              label: loc.currentParish,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_groom_diocese'),
              label: loc.currentDiocese,
              icon: Icons.location_city_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle(loc.brideDetails),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('no_bride_name'),
              label: loc.name,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dob,
              selectedDate: _formData['no_bride_dob'],
              onTap: () async {
                final date = await _pickDate(context, _formData['no_bride_dob']);
                if (date != null) setState(() => _formData['no_bride_dob'] = date);
              },
              loc: loc,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dateOfBaptism,
              selectedDate: _formData['no_bride_bapt_date'],
              onTap: () async {
                final date = await _pickDate(context, _formData['no_bride_bapt_date']);
                if (date != null) setState(() => _formData['no_bride_bapt_date'] = date);
              },
              loc: loc,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_bride_father'),
              label: loc.fatherName,
              icon: Icons.person,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_bride_mother'),
              label: loc.motherName,
              icon: Icons.person_3_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_bride_address'),
              label: loc.homeAddress,
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_bride_parish'),
              label: loc.currentParish,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('no_bride_diocese'),
              label: loc.currentDiocese,
              icon: Icons.location_city_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle(loc.impedimentsLabel),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('no_impediments'),
              label: loc.impediments,
              icon: Icons.warning_amber_rounded,
              maxLines: 3,
            ),
          ]),
        ];

      case CertificateType.BAPTISM:
        return [
          _buildFormSectionTitle(loc.details),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('bap_name'),
              label: loc.name,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
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
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dateOfBaptism,
              selectedDate: _formData['bap_date'],
              onTap: () async {
                final date = await _pickDate(context, _formData['bap_date']);
                if (date != null) setState(() => _formData['bap_date'] = date);
              },
              loc: loc,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('bap_place'),
              label: loc.placeOfBaptism,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle('${loc.fatherName} & ${loc.motherName}'),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('bap_father'),
              label: loc.fatherName,
              icon: Icons.person,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('bap_mother'),
              label: loc.motherName,
              icon: Icons.person_3_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('bap_residence'),
              label: loc.homeAddress,
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('bap_godfather'),
              label: loc.godfatherName,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('bap_godmother'),
              label: loc.godmotherName,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle('Ecclesiastical details'),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('bap_issuing_diocese'),
              label: loc.issuingDiocese,
              icon: Icons.location_city_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('bap_minister'),
              label: loc.ministerOfBaptism,
              icon: Icons.assignment_ind_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('bap_registry_book'),
              label: '${loc.registryBook} (${loc.keptAt})',
              icon: Icons.menu_book_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),
        ];



      case CertificateType.MARRIAGE_PREPARATION:
        if (_getController('prep_target_center').text.isEmpty) {
          _getController('prep_target_center').text = 'Family Apostolate Centre, Vlangamuri';
        }
        return [
          _buildFormSectionTitle(loc.marriagePreparation),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('prep_target_center'),
              label: loc.targetCenter,
              icon: Icons.business_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('prep_course_category'),
              label: loc.courseCategory,
              icon: Icons.calendar_today_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle(loc.details),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('prep_candidate_name'),
              label: loc.name,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildGenderDropdown(loc, isDark, stateKey: 'prep_gender'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('prep_parent_name'),
              label: '${loc.fatherName} / ${loc.motherName} (Son/Daughter of...)',
              icon: Icons.people_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle('Home Parish Registry'),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('prep_home_parish'),
              label: loc.issuingParish,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
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
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('prep_diocese'),
              label: loc.issuingDiocese,
              icon: Icons.location_city_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),
        ];

      case CertificateType.MARRIAGE:
        return [
          _buildFormSectionTitle(loc.marriageLocation),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('mar_issuing_diocese'),
              label: loc.issuingDiocese,
              icon: Icons.location_city_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_location'),
              label: loc.marriageLocation,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
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
                if (date != null) setState(() => _formData['mar_date'] = date);
              },
              loc: loc,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_officiating_priest'),
              label: loc.officiatingPriest,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle(loc.groomDetails),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('mar_groom_name'),
              label: loc.name,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_groom_father'),
              label: loc.fatherName,
              icon: Icons.person,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_groom_mother'),
              label: loc.motherName,
              icon: Icons.person_3_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_groom_parish'),
              label: loc.currentParish,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_groom_pob'),
              label: loc.placeOfBirth,
              icon: Icons.location_on_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dob,
              selectedDate: _formData['mar_groom_dob'],
              onTap: () async {
                final date = await _pickDate(context, _formData['mar_groom_dob']);
                if (date != null) setState(() => _formData['mar_groom_dob'] = date);
              },
              loc: loc,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_groom_place_bapt'),
              label: loc.placeOfBaptism,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dateOfBaptism,
              selectedDate: _formData['mar_groom_bapt_date'],
              onTap: () async {
                final date = await _pickDate(context, _formData['mar_groom_bapt_date']);
                if (date != null) setState(() => _formData['mar_groom_bapt_date'] = date);
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
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle(loc.brideDetails),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('mar_bride_name'),
              label: loc.name,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_bride_father'),
              label: loc.fatherName,
              icon: Icons.person,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_bride_mother'),
              label: loc.motherName,
              icon: Icons.person_3_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_bride_parish'),
              label: loc.currentParish,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_bride_pob'),
              label: loc.placeOfBirth,
              icon: Icons.location_on_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dob,
              selectedDate: _formData['mar_bride_dob'],
              onTap: () async {
                final date = await _pickDate(context, _formData['mar_bride_dob']);
                if (date != null) setState(() => _formData['mar_bride_dob'] = date);
              },
              loc: loc,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_bride_place_bapt'),
              label: loc.placeOfBaptism,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              label: loc.dateOfBaptism,
              selectedDate: _formData['mar_bride_bapt_date'],
              onTap: () async {
                final date = await _pickDate(context, _formData['mar_bride_bapt_date']);
                if (date != null) setState(() => _formData['mar_bride_bapt_date'] = date);
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
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle(loc.witness1),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('mar_w1_name'),
              label: loc.witnessName,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_w1_parish'),
              label: loc.witnessParish,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_w1_address'),
              label: loc.witnessAddress,
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),

          _buildFormSectionTitle(loc.witness2),
          _buildSectionCard(children: [
            _buildTextField(
              controller: _getController('mar_w2_name'),
              label: loc.witnessName,
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_w2_parish'),
              label: loc.witnessParish,
              icon: Icons.church_outlined,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _getController('mar_w2_address'),
              label: loc.witnessAddress,
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (val) => val == null || val.isEmpty ? loc.fieldRequired : null,
            ),
          ]),
        ];
    }
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _buildGenderDropdown(AppLocalizations loc, bool isDark, {String stateKey = 'bap_gender'}) {
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
    final dateStr = selectedDate == null
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

  Widget _buildHistoryTab(
      AppLocalizations loc, ThemeData theme, bool isDark) {
    return FutureBuilder<List<CertificateRequest>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.red[400], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    loc.errorOccurred,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshRequests,
                    child: const Text('Retry'),
                  )
                ],
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _refreshRequests(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF5D3A99).withValues(alpha: 0.08),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_outlined,
                          color: Color(0xFF5D3A99),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.noRequestsFound,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshRequests(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _CertificateRequestCard(
                request: requests[index],
                loc: loc,
                theme: theme,
                isDark: isDark,
                isPriest: false,
              );
            },
          ),
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
}

class _CertificateRequestCard extends StatefulWidget {
  final CertificateRequest request;
  final AppLocalizations loc;
  final ThemeData theme;
  final bool isDark;
  final bool isPriest;
  final void Function(Map<String, dynamic>)? onApprove;
  final void Function(String?)? onReject;

  const _CertificateRequestCard({
    required this.request,
    required this.loc,
    required this.theme,
    required this.isDark,
    required this.isPriest,
    this.onApprove,
    this.onReject,
  });

  @override
  State<_CertificateRequestCard> createState() =>
      _CertificateRequestCardState();
}

class _CertificateRequestCardState extends State<_CertificateRequestCard> {
  bool _isExpanded = false;
  bool _isDownloading = false;

  Future<void> _downloadCertificate() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final service = CertificateService();
      final typeName = _getTypeDisplayName(widget.request.type, widget.loc);
      final message = await service.downloadCertificate(widget.request.id, typeName);
      
      if (mounted) {
        final isSuccess = message.contains('successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.info_outline, 
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: isSuccess ? Colors.green[600] : Colors.amber[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
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
          _isDownloading = false;
        });
      }
    }
  }


  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogDatePicker({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    final dateStr = selectedDate == null
        ? 'Select Date'
        : DateFormat('MMMM dd, yyyy').format(selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(dateStr, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _showDialogDatePicker(BuildContext ctx, DateTime? initial) async {
    return await showDatePicker(
      context: ctx,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
  }

  void _showApproveConfirm(BuildContext context) {
    final TextEditingController field1Controller = TextEditingController();
    final TextEditingController confPlaceController = TextEditingController(
      text: widget.request.details['placeOfConfirmation']?.toString() ?? '',
    );
    DateTime? selectedDate = DateTime.now();
    DateTime? confDate = widget.request.details['dateOfConfirmation'] != null
        ? DateTime.tryParse(widget.request.details['dateOfConfirmation'].toString()) ?? DateTime.now()
        : DateTime.now();

    // Controllers for editing certificate-specific details (flattened in approval payload)
    final Map<String, TextEditingController> detailControllers = {};
    String permissionTypeVal = widget.request.details['permissionType']?.toString() ?? 'PUBLISH_BANNS_MARRIAGE';

    // Prefill controllers based on request type
    switch (widget.request.type) {
      case CertificateType.NIHIL_OBSTAT:
        detailControllers['issuingParish'] = TextEditingController(text: widget.request.details['issuingParish']?.toString() ?? '');
        detailControllers['issuingDiocese'] = TextEditingController(text: widget.request.details['issuingDiocese']?.toString() ?? '');
        detailControllers['impediments'] = TextEditingController(text: widget.request.details['impediments']?.toString() ?? '');
        break;
      case CertificateType.BAPTISM:
        detailControllers['placeOfBirth'] = TextEditingController(text: widget.request.details['placeOfBirth']?.toString() ?? '');
        detailControllers['placeOfBaptism'] = TextEditingController(text: widget.request.details['placeOfBaptism']?.toString() ?? '');
        detailControllers['ministerOfBaptism'] = TextEditingController(text: widget.request.details['ministerOfBaptism']?.toString() ?? '');
        detailControllers['registryBook'] = TextEditingController(text: widget.request.details['registryBook']?.toString() ?? '');
        detailControllers['issuingDiocese'] = TextEditingController(text: widget.request.details['issuingDiocese']?.toString() ?? '');
        break;
      case CertificateType.MARRIAGE_PREPARATION:
        detailControllers['targetCenter'] = TextEditingController(text: widget.request.details['targetCenter']?.toString() ?? '');
        detailControllers['courseCategory'] = TextEditingController(text: widget.request.details['courseCategory']?.toString() ?? '');
        break;
      case CertificateType.MARRIAGE:
        detailControllers['issuingDiocese'] = TextEditingController(text: widget.request.details['issuingDiocese']?.toString() ?? '');
        detailControllers['locationOfMarriage'] = TextEditingController(text: widget.request.details['locationOfMarriage']?.toString() ?? '');
        detailControllers['substationName'] = TextEditingController(text: widget.request.details['substationName']?.toString() ?? '');
        detailControllers['officiatingPriest'] = TextEditingController(text: widget.request.details['officiatingPriest']?.toString() ?? '');
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        String? certNoErrorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final List<Widget> dialogFields = [];
            String title = widget.loc.approveConfirm;

            Widget buildSectionHeader(String title) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFF5D3A99),
                    letterSpacing: 0.8,
                  ),
                ),
              );
            }

            switch (widget.request.type) {
              case CertificateType.NIHIL_OBSTAT:
                title = '${widget.loc.approve} - ${widget.loc.clearanceForm}';
                dialogFields.add(
                  _buildDialogTextField(
                    controller: field1Controller,
                    label: widget.loc.certificateNo,
                    hint: 'e.g. NO-2026-004',
                    errorText: certNoErrorText,
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogDatePicker(
                    label: widget.loc.issueDate,
                    selectedDate: selectedDate,
                    onTap: () async {
                      final picked = await _showDialogDatePicker(ctx, selectedDate);
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                );

                dialogFields.add(const SizedBox(height: 12));
                dialogFields.add(const Divider());
                dialogFields.add(buildSectionHeader("Edit Certificate Details"));

                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['issuingParish']!,
                    label: "Issuing Parish",
                    hint: "Parish name",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['issuingDiocese']!,
                    label: "Issuing Diocese",
                    hint: "Diocese name",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Permission Type",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: permissionTypeVal,
                        items: const [
                          DropdownMenuItem(value: 'ASSIST_AT_ENGAGEMENT', child: Text('Assist at Engagement Contract')),
                          DropdownMenuItem(value: 'PUBLISH_BANNS_MARRIAGE', child: Text('Publish Banns for Marriage')),
                          DropdownMenuItem(value: 'ASSIST_AT_THE_MARRIAGE', child: Text('Assist at the Marriage')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              permissionTypeVal = v;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['impediments']!,
                    label: "Impediments (if any)",
                    hint: "e.g. None",
                  ),
                );
                break;

              case CertificateType.BAPTISM:
                title = '${widget.loc.approve} - ${widget.loc.baptism}';
                dialogFields.add(
                  _buildDialogTextField(
                    controller: field1Controller,
                    label: widget.loc.certificateNo,
                    hint: 'e.g. BAP-2026-089',
                    errorText: certNoErrorText,
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogDatePicker(
                    label: widget.loc.issueDate,
                    selectedDate: selectedDate,
                    onTap: () async {
                      final picked = await _showDialogDatePicker(ctx, selectedDate);
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogDatePicker(
                    label: widget.loc.dateOfConfirmation,
                    selectedDate: confDate,
                    onTap: () async {
                      final picked = await _showDialogDatePicker(ctx, confDate);
                      if (picked != null) {
                        setDialogState(() {
                          confDate = picked;
                        });
                      }
                    },
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: confPlaceController,
                    label: widget.loc.placeOfConfirmation,
                    hint: 'e.g. St. Mary\'s Cathedral',
                  ),
                );

                dialogFields.add(const SizedBox(height: 12));
                dialogFields.add(const Divider());
                dialogFields.add(buildSectionHeader("Edit Certificate Details"));

                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['placeOfBirth']!,
                    label: "Place of Birth",
                    hint: "Location",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['placeOfBaptism']!,
                    label: "Place of Baptism",
                    hint: "Parish name",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['ministerOfBaptism']!,
                    label: "Minister of Baptism",
                    hint: "Priest name",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['registryBook']!,
                    label: "Registry Book Location",
                    hint: "Volume / page",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['issuingDiocese']!,
                    label: "Issuing Diocese",
                    hint: "Diocese name",
                  ),
                );
                break;

              case CertificateType.MARRIAGE_PREPARATION:
                title = '${widget.loc.approve} - ${widget.loc.marriagePreparation}';
                dialogFields.add(
                  _buildDialogDatePicker(
                    label: widget.loc.issueDate,
                    selectedDate: selectedDate,
                    onTap: () async {
                      final picked = await _showDialogDatePicker(ctx, selectedDate);
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                );

                dialogFields.add(const SizedBox(height: 12));
                dialogFields.add(const Divider());
                dialogFields.add(buildSectionHeader("Edit Certificate Details"));

                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['targetCenter']!,
                    label: "Target Center Name",
                    hint: "Center name",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['courseCategory']!,
                    label: "Course Category / Dates",
                    hint: "e.g. Regular (May 10-12)",
                  ),
                );
                break;

              case CertificateType.MARRIAGE:
                title = '${widget.loc.approve} - ${widget.loc.marriage}';
                dialogFields.add(
                  _buildDialogTextField(
                    controller: field1Controller,
                    label: widget.loc.registerNo,
                    hint: 'e.g. REG-2026-015',
                    errorText: certNoErrorText,
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogDatePicker(
                    label: widget.loc.issueDate,
                    selectedDate: selectedDate,
                    onTap: () async {
                      final picked = await _showDialogDatePicker(ctx, selectedDate);
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                );

                dialogFields.add(const SizedBox(height: 12));
                dialogFields.add(const Divider());
                dialogFields.add(buildSectionHeader("Edit Certificate Details"));

                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['issuingDiocese']!,
                    label: "Issuing Diocese",
                    hint: "Diocese name",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['locationOfMarriage']!,
                    label: "Location of Marriage",
                    hint: "Parish name",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['substationName']!,
                    label: "Substation Name",
                    hint: "Substation name",
                  ),
                );
                dialogFields.add(const SizedBox(height: 16));
                dialogFields.add(
                  _buildDialogTextField(
                    controller: detailControllers['officiatingPriest']!,
                    label: "Officiating Priest",
                    hint: "Priest name",
                  ),
                );
                break;
            }

            return AlertDialog(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.loc.approveConfirm,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ...dialogFields,
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: widget.isDark ? Colors.grey[400] : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final certNo = field1Controller.text.trim();
                    if (widget.request.type != CertificateType.MARRIAGE_PREPARATION && certNo.isEmpty) {
                      setDialogState(() {
                        certNoErrorText = "This field is required";
                      });
                      return;
                    }

                    final Map<String, dynamic> officialDetails = {};
                    final formattedDate = selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                        : DateFormat('yyyy-MM-dd').format(DateTime.now());

                    switch (widget.request.type) {
                      case CertificateType.NIHIL_OBSTAT:
                        officialDetails['certificateNo'] = field1Controller.text.trim();
                        officialDetails['issueDate'] = formattedDate;

                        // Flatten details directly
                        officialDetails['issuingParish'] = detailControllers['issuingParish']!.text.trim();
                        officialDetails['issuingDiocese'] = detailControllers['issuingDiocese']!.text.trim();
                        officialDetails['permissionType'] = permissionTypeVal;
                        officialDetails['impediments'] = detailControllers['impediments']!.text.trim();
                        break;
                      case CertificateType.BAPTISM:
                        officialDetails['certificateNo'] = field1Controller.text.trim();
                        officialDetails['issueDate'] = formattedDate;
                        if (confDate != null) {
                          officialDetails['dateOfConfirmation'] = DateFormat('yyyy-MM-dd').format(confDate!);
                        }
                        officialDetails['placeOfConfirmation'] = confPlaceController.text.trim();

                        // Flatten details directly
                        officialDetails['placeOfBirth'] = detailControllers['placeOfBirth']!.text.trim();
                        officialDetails['placeOfBaptism'] = detailControllers['placeOfBaptism']!.text.trim();
                        officialDetails['ministerOfBaptism'] = detailControllers['ministerOfBaptism']!.text.trim();
                        officialDetails['registryBook'] = detailControllers['registryBook']!.text.trim();
                        officialDetails['issuingDiocese'] = detailControllers['issuingDiocese']!.text.trim();
                        break;

                      case CertificateType.MARRIAGE_PREPARATION:
                        officialDetails['issueDate'] = formattedDate;

                        // Flatten details directly
                        officialDetails['targetCenter'] = detailControllers['targetCenter']!.text.trim();
                        officialDetails['courseCategory'] = detailControllers['courseCategory']!.text.trim();
                        break;
                      case CertificateType.MARRIAGE:
                        officialDetails['registerNo'] = field1Controller.text.trim();
                        officialDetails['issueDate'] = formattedDate;

                        // Flatten details directly
                        officialDetails['issuingDiocese'] = detailControllers['issuingDiocese']!.text.trim();
                        officialDetails['locationOfMarriage'] = detailControllers['locationOfMarriage']!.text.trim();
                        officialDetails['substationName'] = detailControllers['substationName']!.text.trim();
                        officialDetails['officiatingPriest'] = detailControllers['officiatingPriest']!.text.trim();
                        break;
                    }

                    Navigator.of(ctx).pop();
                    if (widget.onApprove != null) {
                      widget.onApprove!(officialDetails);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.loc.approve,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(widget.loc.rejectionReasonPrompt),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.loc.rejectionReasonHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (widget.onReject != null) {
                  widget.onReject!(reasonController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.loc.reject,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeName = _getTypeDisplayName(widget.request.type, widget.loc);
    final formattedDate =
        DateFormat('MMM dd, yyyy').format(widget.request.createdAt);

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: widget.theme.cardColor,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D3A99).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTypeIcon(widget.request.type),
                      color: const Color(0xFF5D3A99),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(widget.request.status),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                if (widget.isPriest && widget.request.requesterName != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.loc.requestedBy}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.request.requesterName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (widget.request.status == CertificateStatus.APPROVED) ...[
                  _buildOfficialDetailsSection(widget.request.type, widget.request.details, widget.loc),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _downloadCertificate,
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 20, color: Colors.white),
                        label: Text(
                          _isDownloading 
                              ? widget.loc.downloadingCertificate 
                              : widget.loc.downloadCertificate,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D3A99),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: const Color(0xFF5D3A99).withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                Text(
                  widget.loc.details.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildDetailsView(widget.request.details, widget.loc),
                if (widget.request.status == CertificateStatus.REJECTED &&
                    widget.request.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50]?.withValues(alpha: widget.isDark ? 0.05 : 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red[200]!.withValues(alpha: widget.isDark ? 0.2 : 0.8),
                      ),
                    ),
                    child: Text(
                      widget.loc.rejectionReason(widget.request.rejectionReason!),
                      style: TextStyle(
                        color: widget.isDark ? Colors.red[300] : Colors.red[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (widget.isPriest && widget.request.status == CertificateStatus.PENDING) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(context),
                          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.red),
                          label: Text(
                            widget.loc.reject,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveConfirm(context),
                          icon: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                          label: Text(
                            widget.loc.approve,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficialDetailsSection(CertificateType type, Map<String, dynamic> details, AppLocalizations loc) {
    final List<Widget> items = [];
    
    switch (type) {
      case CertificateType.NIHIL_OBSTAT:
        if (details.containsKey('certificateNo') || details.containsKey('issueDate')) {
          items.add(_buildDetailRow(loc.certificateNo, details['certificateNo'] ?? 'N/A'));
          items.add(_buildDetailRow(loc.issueDate, _formatDetailDate(details['issueDate'])));
        }
        break;
      case CertificateType.BAPTISM:
        if (details.containsKey('certificateNo') || details.containsKey('issueDate')) {
          items.add(_buildDetailRow(loc.certificateNo, details['certificateNo'] ?? 'N/A'));
          items.add(_buildDetailRow(loc.issueDate, _formatDetailDate(details['issueDate'])));
        }
        if (details.containsKey('dateOfConfirmation') && details['dateOfConfirmation'] != null) {
          items.add(_buildDetailRow(loc.dateOfConfirmation, _formatDetailDate(details['dateOfConfirmation'])));
        }
        if (details.containsKey('placeOfConfirmation') && details['placeOfConfirmation'] != null && details['placeOfConfirmation'].toString().isNotEmpty) {
          items.add(_buildDetailRow(loc.placeOfConfirmation, details['placeOfConfirmation']));
        }
        break;

      case CertificateType.MARRIAGE_PREPARATION:
        if (details.containsKey('issueDate')) {
          items.add(_buildDetailRow(loc.issueDate, _formatDetailDate(details['issueDate'])));
        }
        break;
      case CertificateType.MARRIAGE:
        if (details.containsKey('registerNo') || details.containsKey('issueDate')) {
          items.add(_buildDetailRow(loc.registerNo, details['registerNo'] ?? 'N/A'));
          items.add(_buildDetailRow(loc.issueDate, _formatDetailDate(details['issueDate'])));
        }
        break;
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green[50]?.withValues(alpha: widget.isDark ? 0.05 : 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[200]!.withValues(alpha: widget.isDark ? 0.2 : 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.green[600], size: 18),
              const SizedBox(width: 8),
              const Text(
                'OFFICIAL ISSUANCE DETAILS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.green,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final parsed = DateTime.parse(dateVal.toString());
      return DateFormat('MMMM dd, yyyy').format(parsed);
    } catch (_) {
      return dateVal.toString();
    }
  }

  IconData _getTypeIcon(CertificateType type) {
    switch (type) {
      case CertificateType.BAPTISM:
        return Icons.water_drop_outlined;
      case CertificateType.MARRIAGE:
        return Icons.favorite_border_rounded;

      case CertificateType.MARRIAGE_PREPARATION:
        return Icons.assignment_ind_outlined;
      case CertificateType.NIHIL_OBSTAT:
        return Icons.verified_user_outlined;
    }
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

  Widget _buildStatusBadge(CertificateStatus status) {
    Color color;
    Color textColor;
    String text;

    switch (status) {
      case CertificateStatus.APPROVED:
        color = Colors.green[50]!;
        textColor = Colors.green[800]!;
        text = 'APPROVED';
        break;
      case CertificateStatus.REJECTED:
        color = Colors.red[50]!;
        textColor = Colors.red[800]!;
        text = 'REJECTED';
        break;
      case CertificateStatus.PENDING:
        color = Colors.amber[50]!;
        textColor = Colors.amber[800]!;
        text = 'PENDING';
        break;
    }

    if (widget.isDark) {
      color = color.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  List<Widget> _buildDetailsView(Map<String, dynamic> details, AppLocalizations loc) {
    final List<Widget> items = [];
    final List<String> excludedKeys = [
      'certificateNo',
      'issueDate',
      'receiptNo',
      'paymentDate',
      'registerNo',
      'rejectionReason',
      'dateOfConfirmation',
      'placeOfConfirmation'
    ];

    details.forEach((key, value) {
      if (excludedKeys.contains(key)) return;
      
      String displayKey = key;
      String displayValue = value.toString();

      // Make key display-friendly
      if (key == 'name') {
        displayKey = loc.name;
      } else if (key == 'gender') {
        displayKey = loc.gender;
        displayValue = displayValue.toLowerCase() == 'male' ? loc.male : loc.female;
      } else if (key == 'issuingParish') {
        displayKey = loc.issuingParish;
      } else if (key == 'issuingDiocese') {
        displayKey = loc.issuingDiocese;
      } else if (key == 'permissionType') {
        displayKey = loc.permissionType;
        if (value.toString() == 'ASSIST_AT_ENGAGEMENT') {
          displayValue = loc.assistAtEngagement;
        } else if (value.toString() == 'PUBLISH_BANNS_MARRIAGE') {
          displayValue = loc.publishBannsMarriage;
        } else if (value.toString() == 'ASSIST_AT_THE_MARRIAGE') {
          displayValue = loc.assistAtTheMarriage;
        } else {
          displayValue = loc.publishBannsMarriage;
        }
      } else if (key == 'groomName') {
        displayKey = '${loc.groomDetails} - ${loc.name}';
      } else if (key == 'groomDob') {
        displayKey = '${loc.groomDetails} - ${loc.dob}';
        displayValue = _formatDetailDate(value);
      } else if (key == 'groomBaptismDate') {
        displayKey = '${loc.groomDetails} - ${loc.dateOfBaptism}';
        displayValue = _formatDetailDate(value);
      } else if (key == 'groomFather') {
        displayKey = '${loc.groomDetails} - ${loc.fatherName}';
      } else if (key == 'groomMother') {
        displayKey = '${loc.groomDetails} - ${loc.motherName}';
      } else if (key == 'groomAddress') {
        displayKey = '${loc.groomDetails} - ${loc.homeAddress}';
      } else if (key == 'groomParish') {
        displayKey = '${loc.groomDetails} - ${loc.currentParish}';
      } else if (key == 'groomDiocese') {
        displayKey = '${loc.groomDetails} - ${loc.currentDiocese}';
      } else if (key == 'brideName') {
        displayKey = '${loc.brideDetails} - ${loc.name}';
      } else if (key == 'brideDob') {
        displayKey = '${loc.brideDetails} - ${loc.dob}';
        displayValue = _formatDetailDate(value);
      } else if (key == 'brideBaptismDate') {
        displayKey = '${loc.brideDetails} - ${loc.dateOfBaptism}';
        displayValue = _formatDetailDate(value);
      } else if (key == 'brideFather') {
        displayKey = '${loc.brideDetails} - ${loc.fatherName}';
      } else if (key == 'brideMother') {
        displayKey = '${loc.brideDetails} - ${loc.motherName}';
      } else if (key == 'brideAddress') {
        displayKey = '${loc.brideDetails} - ${loc.homeAddress}';
      } else if (key == 'brideParish') {
        displayKey = '${loc.brideDetails} - ${loc.currentParish}';
      } else if (key == 'brideDiocese') {
        displayKey = '${loc.brideDetails} - ${loc.currentDiocese}';
      } else if (key == 'impediments') {
        displayKey = loc.impedimentsLabel;
      } else if (key == 'dob') {
        displayKey = loc.dob;
        displayValue = _formatDetailDate(value);
      } else if (key == 'placeOfBirth') {
        displayKey = loc.placeOfBirth;
      } else if (key == 'dateOfBaptism') {
        displayKey = loc.dateOfBaptism;
        displayValue = _formatDetailDate(value);
      } else if (key == 'placeOfBaptism') {
        displayKey = loc.placeOfBaptism;
      } else if (key == 'fatherName') {
        displayKey = loc.fatherName;
      } else if (key == 'motherName') {
        displayKey = loc.motherName;
      } else if (key == 'permanentResidence') {
        displayKey = loc.homeAddress;
      } else if (key == 'godfatherName') {
        displayKey = loc.godfatherName;
      } else if (key == 'godmotherName') {
        displayKey = loc.godmotherName;
      } else if (key == 'ministerOfBaptism') {
        displayKey = loc.ministerOfBaptism;
      } else if (key == 'dateOfConfirmation') {
        displayKey = loc.dateOfConfirmation;
        displayValue = _formatDetailDate(value);
      } else if (key == 'placeOfConfirmation') {
        displayKey = loc.placeOfConfirmation;
      } else if (key == 'registryBook') {
        displayKey = loc.registryBook;

      } else if (key == 'targetCenter') {
        displayKey = loc.targetCenter;
      } else if (key == 'parentName') {
        displayKey = '${loc.fatherName} / ${loc.motherName}';
      } else if (key == 'homeParish') {
        displayKey = loc.issuingParish;
      } else if (key == 'substationName') {
        displayKey = loc.substationName;
      } else if (key == 'foranateArea') {
        displayKey = loc.foranateArea;
      } else if (key == 'dioceseName') {
        displayKey = loc.issuingDiocese;
      } else if (key == 'courseCategory') {
        displayKey = loc.courseCategory;
      } else if (key == 'locationOfMarriage') {
        displayKey = loc.marriageLocation;
      } else if (key == 'marriageDate') {
        displayKey = loc.marriageDate;
        displayValue = _formatDetailDate(value);
      } else if (key == 'officiatingPriest') {
        displayKey = loc.officiatingPriest;
      } else if (key == 'groomPob') {
        displayKey = '${loc.groomDetails} - ${loc.placeOfBirth}';
      } else if (key == 'groomPlaceBaptism') {
        displayKey = '${loc.groomDetails} - ${loc.placeOfBaptism}';
      } else if (key == 'bridePob') {
        displayKey = '${loc.brideDetails} - ${loc.placeOfBirth}';
      } else if (key == 'bridePlaceBaptism') {
        displayKey = '${loc.brideDetails} - ${loc.placeOfBaptism}';
      } else if (key == 'witness1Name') {
        displayKey = '${loc.witness1} - ${loc.witnessName}';
      } else if (key == 'witness1Parish') {
        displayKey = '${loc.witness1} - ${loc.witnessParish}';
      } else if (key == 'witness1Address') {
        displayKey = '${loc.witness1} - ${loc.witnessAddress}';
      } else if (key == 'witness2Name') {
        displayKey = '${loc.witness2} - ${loc.witnessName}';
      } else if (key == 'witness2Parish') {
        displayKey = '${loc.witness2} - ${loc.witnessParish}';
      } else if (key == 'witness2Address') {
        displayKey = '${loc.witness2} - ${loc.witnessAddress}';
      }

      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$displayKey: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Expanded(
                child: Text(
                  displayValue,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return items;
  }
}
