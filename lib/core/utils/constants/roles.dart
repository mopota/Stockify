class AppRoles {
  static const String superAdmin = 'super_admin';
  static const String admin = 'admin';
  static const String moderator = 'moderator';
  static const String seller = 'seller';
  static const String user = 'user';

  static const String superAdminEmail = 'mohamed.dio555@gmail.com';
}

class AppPermissions {
  static const String publishProducts = 'publish_products';
  static const String editProducts = 'edit_products';
  static const String deleteProducts = 'delete_products';
  static const String manageOrders = 'manage_orders';
  static const String manageUsers = 'manage_users';
  static const String manageCategories = 'manage_categories';
  static const String manageReviews = 'manage_reviews';
  static const String accessDashboard = 'access_dashboard';

  static const List<String> adminDefaultPermissions = [
    publishProducts,
    editProducts,
    deleteProducts,
    manageOrders,
    accessDashboard,
  ];
}
