/// The verbs a pending operation can represent. Pure Dart (no drift import) so
/// repositories can reference it when enqueuing without taking a transitive
/// dependency on the database layer. `tables.dart` re-uses this for the
/// `pending_operations.op_type` column.
enum OpType { create, update, toggle, delete }
