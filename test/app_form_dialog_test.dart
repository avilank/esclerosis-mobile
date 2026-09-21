import 'package:esclerosis_mobile/core/theme/app_spacing.dart';
import 'package:esclerosis_mobile/core/widgets/app_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el teclado no infla el insetPadding del dialogo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
          child: AppFormDialogChrome(
            icon: Icons.apartment_outlined,
            title: 'Nueva sede',
            sectionLabel: 'Datos de la sede',
            onSubmit: _noop,
            content: SizedBox.shrink(),
          ),
        ),
      ),
    );

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(
      dialog.insetPadding,
      const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s7),
    );
  });
}

void _noop() {}
