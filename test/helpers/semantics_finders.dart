// Suite: helper de tests, búsqueda por Semantics.identifier (ids E2E)
// Casos: soporte de CP-MOB-A11Y-002 y -003
// Tipo: helper   Prioridad: P1
// Precondiciones: requiere tester.ensureSemantics()
// Trazabilidad: docs/e2e-selectors.md
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Busca un nodo semántico por su `Semantics.identifier` (los ids de E2E de
/// `docs/e2e-selectors.md`). Requiere `tester.ensureSemantics()`.
FinderBase<SemanticsNode> bySemanticsId(String id) =>
    find.semantics.byPredicate((node) => node.identifier == id);
