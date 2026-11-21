import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_3/main.dart';
import 'package:flutter_application_3/services/auth_service.dart';

void main() {
  testWidgets('Sin sesión guardada la app llega a la pantalla de login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LoginApp());
    await tester.pumpAndSettle();

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('INGRESAR'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });

  test('Validación de contraseña: mínimo 8 caracteres con letras y números', () {
    final auth = AuthService();
    expect(auth.validarPassword('abc'), isNotNull);
    expect(auth.validarPassword('sololetras'), isNotNull);
    expect(auth.validarPassword('12345678'), isNotNull);
    expect(auth.validarPassword('Clave12345'), isNull);
  });

  test('Validación de registro: correo inválido y contraseñas distintas', () {
    final auth = AuthService();
    expect(
      auth.validarRegistro(
        nombre: 'Ana',
        correo: 'sin-arroba',
        password: 'Clave12345',
        confirmarpassword: 'Clave12345',
      ),
      isNotNull,
    );
    expect(
      auth.validarRegistro(
        nombre: 'Ana',
        correo: 'ana@correo.com',
        password: 'Clave12345',
        confirmarpassword: 'Otra12345',
      ),
      isNotNull,
    );
    expect(
      auth.validarRegistro(
        nombre: 'Ana',
        correo: 'ana@correo.com',
        password: 'Clave12345',
        confirmarpassword: 'Clave12345',
      ),
      isNull,
    );
  });
}
