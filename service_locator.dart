import '../../domain/repositories/nabbeh_repository.dart';
import 'nabbeh_repository_impl.dart';
import '../datasource/local_data_source.dart';

/// محدد الخدمات المبسط — نقطة وصول واحدة للمستودع في كامل التطبيق
class ServiceLocator {
  ServiceLocator._();
  static final NabbehRepository repo = NabbehRepositoryImpl(LocalDataSource());
}
