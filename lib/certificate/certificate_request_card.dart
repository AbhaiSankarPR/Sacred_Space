import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'certificate_model.dart';
import 'certificate_service.dart';

class CertificateRequestCard extends StatefulWidget {
  final CertificateRequest request;
  final AppLocalizations loc;
  final ThemeData theme;
  final bool isDark;
  final bool isPriest;
  final void Function(Map<String, dynamic>)? onApprove;
  final void Function(String?)? onReject;

  const CertificateRequestCard({
    super.key,
    required this.request,
    required this.loc,
    required this.theme,
    required this.isDark,
    required this.isPriest,
    this.onApprove,
    this.onReject,
  });

  @override
  State<CertificateRequestCard> createState() =>
      _CertificateRequestCardState();
}

class _CertificateRequestCardState extends State<CertificateRequestCard> {
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
