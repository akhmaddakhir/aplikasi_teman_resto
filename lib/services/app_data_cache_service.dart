import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/malang_restaurant_locations.dart';
import '../models/notification_model.dart';
import '../models/partner_model.dart';
import '../models/restaurant_area_model.dart';
import '../models/user_model.dart';
import '../models/wishlist_item_model.dart';

class CachedFirestoreDocument {
  final String id;
  final Map<String, dynamic> data;

  const CachedFirestoreDocument({
    required this.id,
    required this.data,
  });
}

class CachedPartnerContext {
  final String firebaseUid;
  final String userDocId;
  final String customUserId;
  final String? role;
  final String? partnerId;
  final String? restaurantId;
  final List<String> restaurantIds;
  final String? email;
  final String? fullName;

  const CachedPartnerContext({
    required this.firebaseUid,
    required this.userDocId,
    required this.customUserId,
    this.role,
    this.partnerId,
    this.restaurantId,
    this.restaurantIds = const [],
    this.email,
    this.fullName,
  });

  bool get hasPartnerRole => role?.toLowerCase() == 'partner';
}

class _CachedAreas {
  final List<RestaurantArea> areas;
  final bool includesInactive;

  const _CachedAreas({
    required this.areas,
    required this.includesInactive,
  });
}

class AppDataCacheService extends ChangeNotifier {
  static final AppDataCacheService _instance = AppDataCacheService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AppDataCacheService() => _instance;

  AppDataCacheService._internal();

  String? _firebaseUid;
  String? _userDocId;
  UserModel? _currentUserData;
  Map<String, dynamic>? _currentUserRawData;
  CachedPartnerContext? _partnerContext;
  PartnerModel? _partnerData;
  Future<void>? _preloadFuture;
  bool _isPreloading = false;
  bool _hasPreloaded = false;
  bool _mainRestaurantsLoaded = false;
  bool _myRestaurantsLoaded = false;
  bool _userBookingsLoaded = false;
  bool _wishlistLoaded = false;
  bool _notificationsLoaded = false;
  bool _userReviewCountLoaded = false;
  int _userReviewCount = 0;

  final Map<String, String> _errors = {};
  final Map<String, PartnerModel> _restaurantsById = {};
  final Map<String, List<CachedFirestoreDocument>> _menusByRestaurantId = {};
  final Map<String, _CachedAreas> _areasByRestaurantId = {};
  final Map<String, List<CachedFirestoreDocument>> _restaurantBookings = {};

  List<PartnerModel> _myRestaurants = [];
  List<PartnerModel> _mainRestaurants = [];
  List<CachedFirestoreDocument> _userBookings = [];
  List<WishlistItemModel> _wishlistItems = [];
  List<NotificationModel> _notifications = [];
  Set<String> _wishlistedRestaurantIds = {};

  bool get isPreloading => _isPreloading;
  bool get hasPreloaded => _hasPreloaded;
  bool get hasMainRestaurantsCache => _mainRestaurantsLoaded;
  bool get hasMyRestaurantsCache => _myRestaurantsLoaded;
  bool get hasWishlistCache => _wishlistLoaded;
  bool hasMenusCacheForRestaurant(String restaurantId) =>
      _menusByRestaurantId.containsKey(restaurantId);
  bool hasRestaurantBookingsCache(String restaurantId) =>
      _restaurantBookings.containsKey(restaurantId);
  String? get firebaseUid => _firebaseUid;
  String? get userDocId => _userDocId;
  int get cachedUserReviewCount => _userReviewCount;
  Map<String, String> get preloadErrors => Map.unmodifiable(_errors);

  Future<void> preloadAfterLogin({UserModel? user}) {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      clearCacheOnLogout();
      return Future.value();
    }

    debugPrint('[PRELOAD_DEBUG] login berhasil: ${firebaseUser.uid}');

    if (_firebaseUid != null && _firebaseUid != firebaseUser.uid) {
      clearCacheOnLogout();
    }

    _firebaseUid = firebaseUser.uid;
    if (user != null && user.firebaseUid == firebaseUser.uid) {
      _currentUserData = user;
      _userDocId = user.uid.trim().isNotEmpty ? user.uid.trim() : _userDocId;
    }

    if (_preloadFuture != null) return _preloadFuture!;
    if (_hasPreloaded && user == null) return Future.value();

    _preloadFuture = _runPreload(firebaseUser.uid, user).whenComplete(() {
      _preloadFuture = null;
    });
    return _preloadFuture!;
  }

  Future<void> refreshData() {
    final firebaseUid = _auth.currentUser?.uid ?? _firebaseUid;
    if (firebaseUid == null) return Future.value();
    return _runPreload(firebaseUid, _currentUserData);
  }

  void clearCacheOnLogout() {
    debugPrint('[PRELOAD_DEBUG] cache dipakai clearCacheOnLogout');
    _firebaseUid = null;
    _userDocId = null;
    _currentUserData = null;
    _currentUserRawData = null;
    _partnerContext = null;
    _partnerData = null;
    _preloadFuture = null;
    _isPreloading = false;
    _hasPreloaded = false;
    _mainRestaurantsLoaded = false;
    _myRestaurantsLoaded = false;
    _userBookingsLoaded = false;
    _wishlistLoaded = false;
    _notificationsLoaded = false;
    _userReviewCountLoaded = false;
    _userReviewCount = 0;
    _errors.clear();
    _restaurantsById.clear();
    _menusByRestaurantId.clear();
    _areasByRestaurantId.clear();
    _restaurantBookings.clear();
    _myRestaurants = [];
    _mainRestaurants = [];
    _userBookings = [];
    _wishlistItems = [];
    _notifications = [];
    _wishlistedRestaurantIds = {};
    notifyListeners();
  }

  UserModel? getCurrentUserData({String debugSource = 'unknown'}) {
    _logCacheUse(debugSource, 'current user');
    return _currentUserData;
  }

  Map<String, dynamic>? getCurrentUserRawData(
      {String debugSource = 'unknown'}) {
    _logCacheUse(debugSource, 'raw user');
    return _currentUserRawData == null
        ? null
        : Map<String, dynamic>.from(_currentUserRawData!);
  }

  CachedPartnerContext? getPartnerData({String debugSource = 'unknown'}) {
    _logCacheUse(debugSource, 'partner context');
    return _partnerContext;
  }

  PartnerModel? getPartnerRequest({String debugSource = 'unknown'}) {
    _logCacheUse(debugSource, 'partner request');
    return _partnerData;
  }

  List<PartnerModel> getMyRestaurants({String debugSource = 'unknown'}) {
    _logCacheUse(debugSource, 'my restaurants');
    return List.unmodifiable(_myRestaurants);
  }

  List<PartnerModel> getCachedRestaurants({String debugSource = 'unknown'}) {
    _logCacheUse(debugSource, 'main restaurants');
    return List.unmodifiable(_mainRestaurants);
  }

  PartnerModel? getRestaurantById(
    String restaurantId, {
    String debugSource = 'unknown',
  }) {
    _logCacheUse(debugSource, 'restaurant $restaurantId');
    return _restaurantsById[restaurantId];
  }

  List<CachedFirestoreDocument> getCachedUserBookings({
    String debugSource = 'unknown',
  }) {
    _logCacheUse(debugSource, 'user bookings');
    return List.unmodifiable(_userBookings);
  }

  List<CachedFirestoreDocument> getCachedRestaurantBookings(
    String restaurantId, {
    String debugSource = 'unknown',
  }) {
    _logCacheUse(debugSource, 'restaurant bookings $restaurantId');
    return List.unmodifiable(_restaurantBookings[restaurantId] ?? const []);
  }

  List<WishlistItemModel> getCachedWishlistItems({
    String debugSource = 'unknown',
  }) {
    _logCacheUse(debugSource, 'wishlist');
    return List.unmodifiable(_wishlistItems);
  }

  Set<String> getCachedWishlistedRestaurantIds({
    String debugSource = 'unknown',
  }) {
    _logCacheUse(debugSource, 'wishlist ids');
    return Set.unmodifiable(_wishlistedRestaurantIds);
  }

  List<NotificationModel> getCachedNotifications({
    String debugSource = 'unknown',
  }) {
    _logCacheUse(debugSource, 'notifications');
    return List.unmodifiable(_notifications);
  }

  List<CachedFirestoreDocument> getCachedMenusForRestaurant(
    String restaurantId, {
    String debugSource = 'unknown',
  }) {
    _logCacheUse(debugSource, 'menus $restaurantId');
    return List.unmodifiable(_menusByRestaurantId[restaurantId] ?? const []);
  }

  List<RestaurantArea> getCachedAreasForRestaurant(
    String restaurantId, {
    bool activeOnly = false,
    String debugSource = 'unknown',
  }) {
    _logCacheUse(debugSource, 'areas $restaurantId');
    final cached = _areasByRestaurantId[restaurantId];
    if (cached == null) return const [];
    final areas = activeOnly
        ? cached.areas.where((area) => area.isActive).toList()
        : cached.areas;
    return List.unmodifiable(areas);
  }

  Future<List<PartnerModel>> getOrLoadMainRestaurants({
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    if (!forceRefresh && _mainRestaurantsLoaded) {
      _logCacheUse(debugSource, 'main restaurants');
      return getCachedRestaurants(debugSource: debugSource);
    }

    await _guard('restoran utama', () => _loadMainRestaurants());
    return getCachedRestaurants(debugSource: debugSource);
  }

  Future<List<PartnerModel>> getOrLoadMyRestaurants({
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    if (!forceRefresh && _myRestaurantsLoaded) {
      _logCacheUse(debugSource, 'my restaurants');
      return getMyRestaurants(debugSource: debugSource);
    }

    await _guard('restaurant', () => _loadMyRestaurants());
    return getMyRestaurants(debugSource: debugSource);
  }

  Future<List<CachedFirestoreDocument>> getOrLoadUserBookings({
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    if (!forceRefresh && _userBookingsLoaded) {
      _logCacheUse(debugSource, 'user bookings');
      return getCachedUserBookings(debugSource: debugSource);
    }

    await _guard('booking', () => _loadUserBookings());
    return getCachedUserBookings(debugSource: debugSource);
  }

  Future<List<CachedFirestoreDocument>> getOrLoadRestaurantBookings(
    String restaurantId, {
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    if (!forceRefresh && _restaurantBookings.containsKey(restaurantId)) {
      _logCacheUse(debugSource, 'restaurant bookings $restaurantId');
      return getCachedRestaurantBookings(
        restaurantId,
        debugSource: debugSource,
      );
    }

    await _loadRestaurantBookings(restaurantId);
    return getCachedRestaurantBookings(
      restaurantId,
      debugSource: debugSource,
    );
  }

  Future<List<WishlistItemModel>> getOrLoadWishlistItems({
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    if (!forceRefresh && _wishlistLoaded) {
      _logCacheUse(debugSource, 'wishlist');
      return getCachedWishlistItems(debugSource: debugSource);
    }

    await _guard('favorit', () => _loadWishlist());
    return getCachedWishlistItems(debugSource: debugSource);
  }

  Future<List<NotificationModel>> getOrLoadNotifications({
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    if (!forceRefresh && _notificationsLoaded) {
      _logCacheUse(debugSource, 'notifications');
      return getCachedNotifications(debugSource: debugSource);
    }

    await _guard('notifikasi', () => _loadNotifications());
    return getCachedNotifications(debugSource: debugSource);
  }

  Future<int> getOrLoadUserReviewCount({
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    if (!forceRefresh && _userReviewCountLoaded) {
      _logCacheUse(debugSource, 'user review count');
      return _userReviewCount;
    }

    await _guard('review user', () => _loadUserReviewCount());
    return _userReviewCount;
  }

  Future<List<CachedFirestoreDocument>> getOrLoadMenusForRestaurant(
    String restaurantId, {
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    if (!forceRefresh && _menusByRestaurantId.containsKey(restaurantId)) {
      _logCacheUse(debugSource, 'menus $restaurantId');
      return getCachedMenusForRestaurant(
        restaurantId,
        debugSource: debugSource,
      );
    }

    await _loadMenusForRestaurant(restaurantId);
    return getCachedMenusForRestaurant(
      restaurantId,
      debugSource: debugSource,
    );
  }

  Future<List<RestaurantArea>> getOrLoadAreasForRestaurant(
    String restaurantId, {
    bool activeOnly = false,
    bool forceRefresh = false,
    String debugSource = 'unknown',
  }) async {
    final cached = _areasByRestaurantId[restaurantId];
    final canUseCache = cached != null &&
        !forceRefresh &&
        (activeOnly || cached.includesInactive);
    if (canUseCache) {
      _logCacheUse(debugSource, 'areas $restaurantId');
      return getCachedAreasForRestaurant(
        restaurantId,
        activeOnly: activeOnly,
        debugSource: debugSource,
      );
    }

    await _loadAreasForRestaurant(
      restaurantId,
      activeOnly: activeOnly,
      markIncludesInactive: !activeOnly,
    );
    return getCachedAreasForRestaurant(
      restaurantId,
      activeOnly: activeOnly,
      debugSource: debugSource,
    );
  }

  Future<void> refreshWishlist() async {
    await _guard('favorit', () => _loadWishlist());
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    await _guard('notifikasi', () => _loadNotifications());
    notifyListeners();
  }

  void setCurrentUserData(UserModel user, {Map<String, dynamic>? rawData}) {
    if (_auth.currentUser?.uid != user.firebaseUid) return;
    if (_firebaseUid != null && _firebaseUid != user.firebaseUid) {
      clearCacheOnLogout();
    }
    _firebaseUid = user.firebaseUid;
    _userDocId = user.uid;
    _currentUserData = user;
    if (rawData != null) _currentUserRawData = rawData;
    notifyListeners();
  }

  void upsertRestaurant(PartnerModel restaurant) {
    if (restaurant.id.trim().isEmpty) return;
    _restaurantsById[restaurant.id] = restaurant;
    _myRestaurants = [
      restaurant,
      ..._myRestaurants.where((item) => item.id != restaurant.id),
    ]..sort(_sortPartner);
    _mainRestaurants = [
      restaurant,
      ..._mainRestaurants.where((item) => item.id != restaurant.id),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void removeRestaurant(String restaurantId) {
    _restaurantsById.remove(restaurantId);
    _myRestaurants =
        _myRestaurants.where((item) => item.id != restaurantId).toList();
    _mainRestaurants =
        _mainRestaurants.where((item) => item.id != restaurantId).toList();
    _menusByRestaurantId.remove(restaurantId);
    _areasByRestaurantId.remove(restaurantId);
    _restaurantBookings.remove(restaurantId);
    notifyListeners();
  }

  void setAreasForRestaurant(
    String restaurantId,
    List<RestaurantArea> areas, {
    bool includesInactive = true,
  }) {
    _areasByRestaurantId[restaurantId] = _CachedAreas(
      areas: List.unmodifiable(areas),
      includesInactive: includesInactive,
    );
    notifyListeners();
  }

  void setMenusForRestaurant(
    String restaurantId,
    List<CachedFirestoreDocument> menus,
  ) {
    if (restaurantId.trim().isEmpty) return;
    _menusByRestaurantId[restaurantId] = List.unmodifiable(menus);
    notifyListeners();
  }

  void setRestaurantBookings(
    String restaurantId,
    List<CachedFirestoreDocument> bookings,
  ) {
    if (restaurantId.trim().isEmpty) return;
    final sorted = List<CachedFirestoreDocument>.from(bookings)
      ..sort(_sortCachedDocsByDate);
    _restaurantBookings[restaurantId] = List.unmodifiable(sorted);
    notifyListeners();
  }

  void upsertUserBooking(CachedFirestoreDocument booking) {
    _userBookings = [
      booking,
      ..._userBookings.where((item) => item.id != booking.id),
    ]..sort(_sortCachedDocsByDate);
    notifyListeners();
  }

  Future<void> _runPreload(
    String firebaseUid,
    UserModel? user,
  ) async {
    if (_isPreloading) return;
    _isPreloading = true;
    _errors.clear();
    notifyListeners();

    debugPrint('[PRELOAD_DEBUG] preload dimulai');
    try {
      await _guard('user', () => _loadUser(firebaseUid, user));

      await Future.wait([
        _guard('partner', () => _loadPartner()),
        _guard('restaurant', () => _loadMyRestaurants()),
        _guard('booking', () => _loadUserBookings()),
        _guard('favorit', () => _loadWishlist()),
        _guard('notifikasi', () => _loadNotifications()),
        _guard('restoran utama', () => _loadMainRestaurants()),
        _guard('review user', () => _loadUserReviewCount()),
      ]);

      await Future.wait([
        _guard('menu', () => _loadCommonMenus()),
        _guard('table', () => _loadRequiredAreas()),
        _guard('booking restaurant', () => _loadRestaurantBookingsForMine()),
      ]);

      _hasPreloaded = true;
      debugPrint('[PRELOAD_DEBUG] preload selesai');
    } finally {
      _isPreloading = false;
      notifyListeners();
    }
  }

  Future<void> _guard(String label, Future<void> Function() loader) async {
    debugPrint('[PRELOAD_DEBUG] mulai load $label');
    try {
      await loader();
      debugPrint('[PRELOAD_DEBUG] selesai load $label');
    } catch (e) {
      _errors[label] = e.toString();
      debugPrint('[PRELOAD_DEBUG] data gagal dimuat ($label): $e');
    }
  }

  Future<void> _loadUser(String firebaseUid, UserModel? initialUser) async {
    DocumentSnapshot<Map<String, dynamic>>? doc;

    Future<DocumentSnapshot<Map<String, dynamic>>?> readUserDoc(
      String? docId,
    ) async {
      final trimmed = docId?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      final snap = await _firestore.collection('users').doc(trimmed).get();
      if (!snap.exists || snap.data() == null) return null;
      if (snap.data()?['firebaseUid']?.toString() != firebaseUid) return null;
      return snap;
    }

    doc = await readUserDoc(initialUser?.uid);

    if (doc == null) {
      final mappingDoc =
          await _firestore.collection('uid_mapping').doc(firebaseUid).get();
      final mappedUserId = mappingDoc.data()?['userId']?.toString();
      doc = await readUserDoc(mappedUserId);
    }

    doc ??= await readUserDoc(firebaseUid);

    if (doc == null) {
      final query = await _firestore
          .collection('users')
          .where('firebaseUid', isEqualTo: firebaseUid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) doc = query.docs.first;
    }

    if (doc != null && doc.data() != null) {
      final data = Map<String, dynamic>.from(doc.data()!);
      data['uid'] = data['uid']?.toString().trim().isNotEmpty == true
          ? data['uid']
          : doc.id;
      data['firebaseUid'] = data['firebaseUid'] ?? firebaseUid;
      _firebaseUid = firebaseUid;
      _userDocId = doc.id;
      _currentUserRawData = data;
      _currentUserData = UserModel.fromFirestore(data);
      _buildPartnerContextFromUser(firebaseUid, doc.id, data);
      return;
    }

    if (initialUser != null) {
      _firebaseUid = firebaseUid;
      _userDocId = initialUser.uid;
      _currentUserData = initialUser;
      _currentUserRawData = initialUser.toFirestore();
      _buildPartnerContextFromUser(
        firebaseUid,
        initialUser.uid,
        _currentUserRawData!,
      );
    }
  }

  Future<void> _loadPartner() async {
    final firebaseUid = _firebaseUid;
    if (firebaseUid == null) return;

    final data = _currentUserRawData;
    if (data != null && _userDocId != null) {
      _buildPartnerContextFromUser(firebaseUid, _userDocId!, data);
    }

    final ids = <String>{
      firebaseUid,
      if (_partnerContext?.customUserId.trim().isNotEmpty == true)
        _partnerContext!.customUserId.trim(),
    };
    final seen = <String>{};
    final requests = <PartnerModel>[];

    for (final id in ids) {
      for (final field in const ['userId', 'uid', 'ownerId']) {
        final key = '$field:$id';
        if (!seen.add(key)) continue;
        final query = await _firestore
            .collection('partners')
            .where(field, isEqualTo: id)
            .limit(1)
            .get();
        for (final doc in query.docs) {
          requests.add(PartnerModel.fromFirestore({
            ...doc.data(),
            'id': doc.id,
          }));
        }
      }
    }

    if (requests.isEmpty) {
      _partnerData = null;
      return;
    }

    requests.sort(_sortPartner);
    _partnerData = requests.first;
  }

  Future<void> _loadMyRestaurants() async {
    final firebaseUid = _firebaseUid;
    final context = _partnerContext;
    if (firebaseUid == null || context == null) return;

    final restaurants = <PartnerModel>[];
    final seenIds = <String>{};

    Future<void> addDoc(DocumentSnapshot<Map<String, dynamic>> doc) async {
      final data = doc.data();
      if (data == null || !seenIds.add(doc.id)) return;
      final partner = _withKnownMalangLocation(PartnerModel.fromFirestore({
        ...data,
        'id': doc.id,
      }));
      restaurants.add(partner);
      _restaurantsById[partner.id] = partner;
    }

    final directRestaurantIds = <String>{
      if (context.restaurantId?.trim().isNotEmpty == true)
        context.restaurantId!.trim(),
      ...context.restaurantIds.where((id) => id.trim().isNotEmpty),
      if (context.partnerId?.trim().isNotEmpty == true)
        context.partnerId!.trim(),
    };

    for (final id in directRestaurantIds) {
      final doc = await _firestore.collection('restaurants').doc(id).get();
      if (doc.exists) await addDoc(doc);
    }

    final ownerValues = <String>{
      firebaseUid,
      context.customUserId,
    }.where((id) => id.trim().isNotEmpty).toSet();

    for (final value in ownerValues) {
      for (final field in const ['ownerId', 'userId', 'uid', 'createdBy']) {
        final query = await _firestore
            .collection('restaurants')
            .where(field, isEqualTo: value)
            .limit(20)
            .get();
        for (final doc in query.docs) {
          await addDoc(doc);
        }
      }
    }

    restaurants.sort(_sortPartner);
    _myRestaurants = restaurants;
    _myRestaurantsLoaded = true;
  }

  Future<void> _loadMainRestaurants() async {
    final query = await _firestore
        .collection('restaurants')
        .where('status', whereIn: ['active', 'approved'])
        .limit(50)
        .get();

    final restaurants = query.docs.map((doc) {
      final partner = _withKnownMalangLocation(PartnerModel.fromFirestore({
        ...doc.data(),
        'id': doc.id,
      }));
      _restaurantsById[partner.id] = partner;
      return partner;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _mainRestaurants = restaurants;
    _mainRestaurantsLoaded = true;
  }

  Future<void> _loadUserBookings() async {
    final firebaseUid = _firebaseUid;
    if (firebaseUid == null) return;

    final customUserId = _partnerContext?.customUserId;
    final snapshots = await Future.wait([
      _firestore
          .collection('reservations')
          .where('userId', isEqualTo: firebaseUid)
          .limit(50)
          .get(),
      if (customUserId != null &&
          customUserId.trim().isNotEmpty &&
          customUserId != firebaseUid)
        _firestore
            .collection('reservations')
            .where('customUserId', isEqualTo: customUserId)
            .limit(50)
            .get(),
    ]);

    final seenIds = <String>{};
    final bookings = <CachedFirestoreDocument>[];
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        if (!seenIds.add(doc.id)) continue;
        bookings.add(CachedFirestoreDocument(
          id: doc.id,
          data: Map<String, dynamic>.from(doc.data()),
        ));
      }
    }

    _userBookings = bookings..sort(_sortCachedDocsByDate);
    _userBookingsLoaded = true;
  }

  Future<void> _loadRestaurantBookingsForMine() async {
    await Future.wait(_myRestaurants.map(
      (restaurant) => _loadRestaurantBookings(restaurant.id),
    ));
  }

  Future<void> _loadRestaurantBookings(String restaurantId) async {
    if (restaurantId.trim().isEmpty) return;
    final query = await _firestore
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .limit(50)
        .get();
    _restaurantBookings[restaurantId] = query.docs
        .map((doc) => CachedFirestoreDocument(
              id: doc.id,
              data: Map<String, dynamic>.from(doc.data()),
            ))
        .toList()
      ..sort(_sortCachedDocsByDate);
  }

  Future<void> _loadWishlist() async {
    final userDocId = _userDocId;
    if (userDocId == null || userDocId.trim().isEmpty) return;

    final query = await _firestore
        .collection('users')
        .doc(userDocId)
        .collection('wishlist')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final items = <WishlistItemModel>[];
    for (final doc in query.docs) {
      final item = WishlistItemModel.fromFirestore({
        ...doc.data(),
        'id': doc.id,
      });
      final restaurant = _restaurantsById[item.restaurantId] ??
          (item.restaurant.id.trim().isNotEmpty ? item.restaurant : null);
      if (restaurant == null) {
        items.add(item);
      } else {
        items.add(WishlistItemModel(
          id: item.id,
          userId: item.userId,
          restaurantId: item.restaurantId,
          restaurant: restaurant,
          createdAt: item.createdAt,
        ));
      }
    }

    _wishlistItems = items;
    _wishlistedRestaurantIds = items
        .map((item) => item.restaurantId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    _wishlistLoaded = true;
  }

  Future<void> _loadNotifications() async {
    final userDocId = _userDocId;
    if (userDocId == null || userDocId.trim().isEmpty) return;

    final query = await _firestore
        .collection('users')
        .doc(userDocId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();

    _notifications = query.docs
        .map((doc) => NotificationModel.fromFirestore(
              id: doc.id,
              data: doc.data(),
            ))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _notificationsLoaded = true;
  }

  Future<void> _loadUserReviewCount() async {
    final firebaseUid = _firebaseUid;
    if (firebaseUid == null) return;

    final query = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: firebaseUid)
        .limit(50)
        .get();
    _userReviewCount = query.docs.length;
    _userReviewCountLoaded = true;
  }

  Future<void> _loadCommonMenus() async {
    final restaurantIds = <String>{
      ..._myRestaurants.map((item) => item.id),
      ..._mainRestaurants.take(6).map((item) => item.id),
    }.where((id) => id.trim().isNotEmpty).toSet();

    await Future.wait(restaurantIds.map(_loadMenusForRestaurant));
  }

  Future<void> _loadMenusForRestaurant(String restaurantId) async {
    if (restaurantId.trim().isEmpty) return;
    final query = await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menus')
        .limit(20)
        .get();
    _menusByRestaurantId[restaurantId] = query.docs
        .map((doc) => CachedFirestoreDocument(
              id: doc.id,
              data: Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  Future<void> _loadRequiredAreas() async {
    final myRestaurantIds = _myRestaurants
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final mainRestaurantIds = _mainRestaurants
        .take(6)
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .where((id) => !myRestaurantIds.contains(id))
        .toSet();

    await Future.wait([
      ...myRestaurantIds.map(
        (id) => _loadAreasForRestaurant(
          id,
          activeOnly: false,
          markIncludesInactive: true,
        ),
      ),
      ...mainRestaurantIds.map(
        (id) => _loadAreasForRestaurant(
          id,
          activeOnly: true,
          markIncludesInactive: false,
        ),
      ),
    ]);
  }

  Future<void> _loadAreasForRestaurant(
    String restaurantId, {
    required bool activeOnly,
    required bool markIncludesInactive,
  }) async {
    if (restaurantId.trim().isEmpty) return;
    Query<Map<String, dynamic>> query = _firestore
        .collection('restaurant_areas')
        .where('restaurantId', isEqualTo: restaurantId);
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.limit(50).get();
    final areas = snapshot.docs
        .map((doc) => RestaurantArea.fromFirestore({
              ...doc.data(),
              'id': doc.id,
              'restaurantId': restaurantId,
            }))
        .toList()
      ..sort((a, b) => a.areaName.compareTo(b.areaName));

    final existing = _areasByRestaurantId[restaurantId];
    if (activeOnly && existing?.includesInactive == true) return;

    _areasByRestaurantId[restaurantId] = _CachedAreas(
      areas: areas,
      includesInactive: markIncludesInactive,
    );
  }

  void _buildPartnerContextFromUser(
    String firebaseUid,
    String docId,
    Map<String, dynamic> data,
  ) {
    final rawUid = data['uid']?.toString();
    final customUserId = docId != firebaseUid
        ? docId
        : rawUid != null && rawUid.trim().isNotEmpty
            ? rawUid.trim()
            : docId;

    _partnerContext = CachedPartnerContext(
      firebaseUid: firebaseUid,
      userDocId: docId,
      customUserId: customUserId,
      role: data['role']?.toString(),
      partnerId: data['partnerId']?.toString(),
      restaurantId: data['restaurantId']?.toString(),
      restaurantIds: List<String>.from(data['restaurantIds'] ?? const []),
      email: data['email']?.toString(),
      fullName: data['fullName']?.toString(),
    );
  }

  PartnerModel _withKnownMalangLocation(PartnerModel partner) {
    final location = findMalangRestaurantLocation(
      restaurantName: partner.restaurantName,
      restaurantAddress: partner.address,
    );
    if (location == null) return partner;

    return partner.copyWith(
      address: location.address,
      latitude: partner.latitude ?? location.latitude,
      longitude: partner.longitude ?? location.longitude,
    );
  }

  int _sortPartner(PartnerModel a, PartnerModel b) {
    final statusRank = _statusRank(a.status).compareTo(_statusRank(b.status));
    if (statusRank != 0) return statusRank;
    return b.createdAt.compareTo(a.createdAt);
  }

  int _statusRank(PartnerStatus status) {
    switch (status) {
      case PartnerStatus.approved:
        return 0;
      case PartnerStatus.pending:
        return 1;
      case PartnerStatus.rejected:
        return 2;
      case PartnerStatus.none:
        return 3;
    }
  }

  int _sortCachedDocsByDate(
    CachedFirestoreDocument a,
    CachedFirestoreDocument b,
  ) {
    final aDate =
        _readDate(a.data['updatedAt']) ?? _readDate(a.data['createdAt']);
    final bDate =
        _readDate(b.data['updatedAt']) ?? _readDate(b.data['createdAt']);
    return (bDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
      aDate ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }

  void _logCacheUse(String source, String dataName) {
    debugPrint('[PRELOAD_DEBUG] cache dipakai di $source: $dataName');
  }
}
