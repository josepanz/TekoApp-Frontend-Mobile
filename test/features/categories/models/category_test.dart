import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/categories/models/category.dart';

Map<String, dynamic> _baseCategoryJson() {
  return {
    'id': 1,
    'referenceId': 'cat-uuid-1',
    'name': 'Plomería',
    'slug': 'plomeria',
    'sortOrder': 0,
    'status': 'ACTIVE',
    'isVisible': true,
    'requiresVerification': false,
    'maxBudgetOptionsPerRequest': 3,
    'createdAt': '2026-08-08T10:00:00.000Z',
  };
}

void main() {
  group('Category.fromJson — campos agregados en M-04 (verificador de drift)',
      () {
    test('parsea todos los campos cuando el backend los devuelve presentes',
        () {
      // Arrange
      final json = {
        ..._baseCategoryJson(),
        'description': 'Servicios de reparación e instalaciones sanitarias',
        'icon': 'wrench-outline',
        'color': '#2ecc71',
        'metadata': {'taxRate': 10},
        'parentCategoryId': 5,
        'lastChangedAt': '2026-08-09T10:00:00.000Z',
      };

      // Act
      final category = Category.fromJson(json);

      // Assert
      expect(
        category.description,
        'Servicios de reparación e instalaciones sanitarias',
      );
      expect(category.sortOrder, 0);
      expect(category.status, CategoryStatus.active);
      expect(category.isVisible, isTrue);
      expect(category.requiresVerification, isFalse);
      expect(category.maxBudgetOptionsPerRequest, 3);
      expect(category.metadata, {'taxRate': 10});
      expect(category.parentCategoryId, 5);
      expect(category.createdAt, DateTime.parse('2026-08-08T10:00:00.000Z'));
      expect(
        category.lastChangedAt,
        DateTime.parse('2026-08-09T10:00:00.000Z'),
      );
    });

    test(
      'los campos nullable ausentes del JSON (no solo null explícito) parsean a null',
      () {
        // Act — _baseCategoryJson() no incluye description/icon/color/metadata/
        // parentCategoryId/lastChangedAt.
        final category = Category.fromJson(_baseCategoryJson());

        // Assert
        expect(category.description, isNull);
        expect(category.icon, isNull);
        expect(category.color, isNull);
        expect(category.metadata, isNull);
        expect(category.parentCategoryId, isNull);
        expect(category.lastChangedAt, isNull);
      },
    );

    test('los distintos valores de status parsean al enum correcto', () {
      expect(
        Category.fromJson({..._baseCategoryJson(), 'status': 'ACTIVE'}).status,
        CategoryStatus.active,
      );
      expect(
        Category.fromJson({..._baseCategoryJson(), 'status': 'INACTIVE'})
            .status,
        CategoryStatus.inactive,
      );
      expect(
        Category.fromJson({..._baseCategoryJson(), 'status': 'PENDING'}).status,
        CategoryStatus.pending,
      );
    });
  });
}
