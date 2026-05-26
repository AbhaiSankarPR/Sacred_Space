import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'transaction_model.dart';
import 'transaction_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _service = TransactionService();

  bool _isSubmitting = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  TransactionType _selectedType = TransactionType.INCOME;
  String? _selectedCategory;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.CASH;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateCategories();
  }

  void _updateCategories() {
    final categories = TransactionCategories.getCategoriesForType(_selectedType);
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final data = {
        "amount": _amountController.text.trim(),
        "type": _selectedType.name,
        "category": _selectedCategory,
        "paymentMethod": _selectedPaymentMethod.name,
        "remarks": _remarksController.text.trim(),
        "date": DateFormat('yyyy-MM-dd').format(_selectedDate),
      };

      await _service.addTransaction(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add transaction.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(loc.newTransaction, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard(
                cardBg,
                isDark,
                child: Column(
                  children: [
                    _buildAmountField(textColor, loc),
                    const Divider(height: 32),
                    _buildTypeSelector(isDark, loc),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                cardBg,
                isDark,
                child: Column(
                  children: [
                    _buildCategoryDropdown(isDark, cardBg, textColor, loc),
                    const SizedBox(height: 16),
                    _buildPaymentMethodDropdown(isDark, cardBg, textColor, loc),
                    const SizedBox(height: 16),
                    _buildDatePicker(context, isDark, cardBg, textColor, loc),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                cardBg,
                isDark,
                child: _buildRemarksField(textColor, loc),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          loc.saveTransaction.toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Color cardBg, bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAmountField(Color textColor, AppLocalizations loc) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      decoration: InputDecoration(
        labelText: loc.amount,
        prefixText: "₹ ",
        prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
        border: InputBorder.none,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Enter amount';
        if (double.tryParse(val) == null) return 'Enter valid number';
        return null;
      },
    );
  }

  Widget _buildTypeSelector(bool isDark, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = TransactionType.INCOME;
                _updateCategories();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedType == TransactionType.INCOME 
                    ? Colors.green.withOpacity(isDark ? 0.2 : 0.1) 
                    : (isDark ? Colors.grey[800] : Colors.grey[100]),
                border: Border.all(color: _selectedType == TransactionType.INCOME ? Colors.green : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  loc.income,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedType == TransactionType.INCOME 
                        ? (isDark ? Colors.green[300] : Colors.green[800]) 
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = TransactionType.EXPENSE;
                _updateCategories();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedType == TransactionType.EXPENSE 
                    ? Colors.red.withOpacity(isDark ? 0.2 : 0.1) 
                    : (isDark ? Colors.grey[800] : Colors.grey[100]),
                border: Border.all(color: _selectedType == TransactionType.EXPENSE ? Colors.red : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  loc.expense,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedType == TransactionType.EXPENSE 
                        ? (isDark ? Colors.red[300] : Colors.red[800]) 
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(bool isDark, Color cardBg, Color textColor, AppLocalizations loc) {
    final categories = TransactionCategories.getCategoriesForType(_selectedType);
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: cardBg,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: loc.category,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: categories.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(TransactionCategories.formatCategory(cat)),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedCategory = val);
      },
      validator: (val) => val == null ? 'Select category' : null,
    );
  }

  Widget _buildPaymentMethodDropdown(bool isDark, Color cardBg, Color textColor, AppLocalizations loc) {
    return DropdownButtonFormField<PaymentMethod>(
      value: _selectedPaymentMethod,
      dropdownColor: cardBg,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: loc.paymentMethod,
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: PaymentMethod.values.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(method.name),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedPaymentMethod = val);
      },
    );
  }

  Widget _buildDatePicker(BuildContext context, bool isDark, Color cardBg, Color textColor, AppLocalizations loc) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark 
                    ? const ColorScheme.dark(primary: Color(0xFF9B59B6), surface: Color(0xFF303030))
                    : const ColorScheme.light(primary: Color(0xFF5D3A99)),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: loc.date,
          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: TextStyle(color: textColor)),
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksField(Color textColor, AppLocalizations loc) {
    return TextFormField(
      controller: _remarksController,
      maxLines: 3,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: loc.remarksOptional,
        border: InputBorder.none,
        hintText: loc.addDetailsHere,
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
    );
  }
}
