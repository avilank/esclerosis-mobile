import 'package:esclerosis_mobile/core/network/api_exception.dart';
import 'package:esclerosis_mobile/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppToast.messageOf', () {
    test('usa el mensaje de ApiException', () {
      expect(
        AppToast.messageOf(const ApiException(message: 'DNI duplicado')),
        'DNI duplicado',
      );
    });

    test('traduce errores genéricos de Nest', () {
      expect(
        AppToast.messageOf(const ApiException(message: 'Unauthorized')),
        'Correo o contraseña incorrectos',
      );
      expect(
        AppToast.messageOf(const ApiException(message: 'Forbidden')),
        'No tienes permiso para esta acción',
      );
    });

    test('limpia el prefijo Exception:', () {
      expect(AppToast.messageOf(Exception('Fallo de red')), 'Fallo de red');
    });

    test('usa fallback si el mensaje queda vacío', () {
      expect(
        AppToast.messageOf(const ApiException(message: '   '), fallback: 'Inténtalo de nuevo'),
        'Inténtalo de nuevo',
      );
    });
  });

  testWidgets('muestra un toast de éxito en pantalla', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => AppToast.success(context, 'Sede creada'),
                child: const Text('mostrar'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('mostrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sede creada'), findsOneWidget);
  });
}
