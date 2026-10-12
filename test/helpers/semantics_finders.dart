import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Busca un nodo semántico por su `Semantics.identifier` (los ids de E2E de
/// `docs/e2e-selectors.md`). Requiere `tester.ensureSemantics()`.
FinderBase<SemanticsNode> bySemanticsId(String id) =>
    find.semantics.byPredicate((node) => node.identifier == id);
