import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/constants/app_strings.dart';

void main() {
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      title: AppStrings.appName,
      home: Scaffold(body: SizedBox.shrink()),
    );
  }
}
