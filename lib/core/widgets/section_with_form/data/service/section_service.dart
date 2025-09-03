import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:form_template/models/data_model.dart';
import 'form_service_mixin.dart';

typedef ModelFromJson<T> = T Function(Map<String, dynamic> json);

class SectionService<T extends DataModel> with FormServiceMixin<T> {
  // string and instance
  static final Map<String, SectionService> instances = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName;
  final ModelFromJson<T> _fromJson;

  SectionService._internal(this._collectionName, this._fromJson) {
    _firestore.collection(_collectionName).snapshots().listen((snapshot) {});
  }
  /////------////////////               ////////                        ///
  @override
  Future<String> create(T item) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  Future<T> delete(T item) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<List<T>> readAll() {
    // TODO: implement readAll
    throw UnimplementedError();
  }

  @override
  Future<T> update(T item) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
