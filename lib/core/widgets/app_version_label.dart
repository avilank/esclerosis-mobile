import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_typography.dart';

/// Muestra `versionName+versionCode` de la app instalada (util para soporte
/// y para verificar que un build fue instalado correctamente).
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Text(
          'v${info.version}+${info.buildNumber}',
          style: AppTypography.caption,
        );
      },
    );
  }
}
