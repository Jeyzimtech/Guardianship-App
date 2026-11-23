import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Dashboard and details count late arrivals from the same records', () async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiClient();
    final records = [
      for (var i = 0; i < 6; i++)
        {'date': '2026-11-${10 + i}', 'status': i < 4 ? 'present' : 'late'},
    ];
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data:
        options.path.startsWith('/attendance/')
          ? {'attendance': records}
          : {'status': 'success', 'attendance_snapshot': {'percentage': 67}},
      ));
    }));
    final provider = StudentProvider(api);
    await provider.selectStudent({'id': 1});
    expect(provider.dashboardData!['attendance_snapshot']['percentage'], 100);
    expect(provider.dashboardData!['attendance_snapshot']['total_days'], 6);
    records.add({'date': '2026-11-16', 'status': 'absent'});
    expect((await provider.fetchAttendance(1)).length, 7);
    expect(provider.dashboardData!['attendance_snapshot']['percentage'], 86);
  });
}
