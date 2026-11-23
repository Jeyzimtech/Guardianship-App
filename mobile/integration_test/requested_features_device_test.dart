import 'package:integration_test/integration_test.dart';
import '../test/requested_features_test.dart' as features;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  features.featureTests(systemBack: false);
}
