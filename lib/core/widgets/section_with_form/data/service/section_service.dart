import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:form_template/models/data_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'form_service_mixin.dart';

typedef ModelFromJson<T> = T Function(Map<String, dynamic> json);

class SectionService<T extends DataModel> with FormServiceMixin<T> {
  // string and instance
  static final Map<String, SectionService> instances = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName;
  final ModelFromJson<T> _fromJson;

  SectionService._internal(this._collectionName, this._fromJson) {
    _firestore.collection(_collectionName).snapshots().listen((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return _fromJson(data);
      }).toList();
      emitData(items);
    });
  }
  //return the same instance
  factory SectionService(String collectionName, ModelFromJson<T> formJson) {
    final String key = '$collectionName-${T.toString()}';

    if (!instances.containsKey(key)) {
      instances[key] = SectionService._internal(collectionName, formJson);
    }
    return instances[key] as SectionService<T>;
  }

  @override
  Future<String> create(T newItem) async {
    try {
      final data = newItem.toJson();
      int nextId = await getNextCategoryId(_collectionName);
      data['id'] = nextId.toString();
      await _firestore.collection(_collectionName).add(data);
      return data['id'] as String;
    } catch (error) {
      throw Exception('Failed to create item: $error');
    }
  }

  @override
  Future<List<T>> readAll() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final item = snapshot.docs.map((doc) => _fromJson(doc.data())).toList();
      return item;
    } catch (error) {
      throw Exception('Failed to read items: $error');
    }
  }

  @override
  Future<T> update(T updateItem) async {
    try {
      final id = (updateItem as dynamic).id;
      if (id == null || id.isEmpty) {
        throw Exception("Item id can't be null for Update operation");
      }

      final query = await _firestore
          .collection(_collectionName)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        throw Exception("No item found with id $id");
      }
      final fireStoreDocId = query.docs.first.id;
      final data = updateItem.toJson();
      await _firestore
          .collection(_collectionName)
          .doc(fireStoreDocId)
          .update(data);
      return updateItem;
    } catch (error) {
      throw Exception('Failed to update item: $error');
    }
  }

  @override
  Future<T> delete(T item) async {
    try {
      final id = (item as dynamic).id;
      if (id == null || id.isEmpty) {
        throw Exception("Item id can't be null for Delete operation");
      }
      final query = await _firestore
          .collection(_collectionName)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        throw Exception("No item found with id $id");
      }
      final fireStoreDocId = query.docs.first.id;
      await _firestore.collection(_collectionName).doc(fireStoreDocId).delete();
      return item;
    } catch (error) {
      throw Exception('Failed to delete item: $error');
    }
  }

  //custom ID increment system through a Cloud Function.
  Future<int> getNextCategoryId(String category) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'getNextCategoryId',
      );

      final result = await callable.call(<String, dynamic>{
        'category': category,
      });
      return result.data['nextId'] as int;
    } on Exception catch (error) {
      throw Exception('Failed to fetch next category ID: $error');
    }
  }
}
