/// ثوابت التطبيق العامة

/// العملات المدعومة (رمز -> اسم عربي)
const Map<String, String> kCurrencies = {
  'SAR': 'ريال سعودي',
  'AED': 'درهم إماراتي',
  'EGP': 'جنيه مصري',
  'KWD': 'دينار كويتي',
  'QAR': 'ريال قطري',
  'JOD': 'دينار أردني',
  'USD': 'دولار أمريكي',
  'EUR': 'يورو',
};

/// إرجاع الاسم العربي للعملة أو الرمز نفسه إن لم يُعرف
String currencyLabel(String code) => kCurrencies[code] ?? code;

/// تنسيق مبلغ مع العملة
String formatAmount(double amount, String code) {
  final String number =
      amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  return '$number ${currencyLabel(code)}';
}
