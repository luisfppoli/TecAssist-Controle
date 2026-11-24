import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/features/auth/models/usuario_model.dart';

void main() {
  group('UsuarioModel', () {
    test('identifica administrador e funcionário', () {
      final admin = UsuarioModel(
        id: 1,
        nome: 'Administrador',
        email: 'admin@tecassist.com',
        tipo: 'ADMIN',
      );
      final funcionario = UsuarioModel(
        id: 2,
        nome: 'Funcionário',
        email: 'funcionario@tecassist.com',
        tipo: 'FUNCIONARIO',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isFuncionario, isFalse);
      expect(funcionario.isAdmin, isFalse);
      expect(funcionario.isFuncionario, isTrue);
    });

    test('converte e serializa os dados do usuário', () {
      final usuario = UsuarioModel.fromJson({
        'id': 9,
        'nome': 'Maria',
        'email': 'maria@tecassist.com',
        'tipo': 'FUNCIONARIO',
        'telefone': '67999990000',
        'fotoPerfil': '/uploads/avatars/maria.png',
        'ativo': true,
        'createdAt': '2026-11-01T10:00:00.000Z',
      });

      expect(usuario.id, 9);
      expect(usuario.nome, 'Maria');
      expect(usuario.telefone, '67999990000');
      expect(usuario.fotoPerfil, '/uploads/avatars/maria.png');
      expect(usuario.ativo, isTrue);

      final json = usuario.toJson();
      expect(json['id'], 9);
      expect(json['email'], 'maria@tecassist.com');
      expect(json['tipo'], 'FUNCIONARIO');
      expect(json['ativo'], isTrue);
    });
  });
}
