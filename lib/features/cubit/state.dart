abstract class AppStates {}

class AppInitialState extends AppStates {}

class AppLoadingState extends AppStates {}

class AppProductsLoadingState extends AppStates {}
class AppProductsLoadedState extends AppStates {}
class AppProductsErrorState extends AppStates {
  final String message;
  AppProductsErrorState(this.message);
}
class AppCategoriesErrorState extends AppStates {
  final String message;
  AppCategoriesErrorState(this.message);
}


class AppOnboardingState extends AppStates {}
class AppAddCategoryLoadingState extends AppStates {}
class AppReadyState extends AppStates {}
class AppLogoutState extends AppStates {}
class AppCategoriesLoadingState extends AppStates {}

class AppAuthenticatedState extends AppStates {}

class AppUnauthenticatedState extends AppStates {}

class AppLoginLoadingState extends AppStates {}

class AppLoginErrorState extends AppStates {
  final String message;
  AppLoginErrorState(this.message);
}

class AppRegisterLoadingState extends AppStates {}
class AppRegisterErrorState extends AppStates {
  final String message;
  AppRegisterErrorState(this.message);
}

class AppAddProductLoadingState extends AppStates {}
class AppAddProductSuccessState extends AppStates {}
class AppAddProductErrorState extends AppStates {
  final String message;
  AppAddProductErrorState(this.message);
}
class AppFavoriteChangedState extends AppStates {}

class AppCartUpdatedState extends AppStates {}
class AppEditProductLoadingState extends AppStates {}
class AppEditProductSuccessState extends AppStates {}
class AppEditProductErrorState extends AppStates {
  final String message;
  AppEditProductErrorState(this.message);
}
class AppDeleteProductLoadingState extends AppStates {}
class AppDeleteProductSuccessState extends AppStates {}
class AppDeleteProductErrorState extends AppStates {
  final String message;
  AppDeleteProductErrorState(this.message);
}
class AppOnboardingCompletedState extends AppStates {}

class AppThemeChangedState extends AppStates {}

class AppRegisterSuccessState extends AppStates {}

class AppLoginSuccessState extends AppStates {}
class AppLogoutSuccessState extends AppStates {}
class AppUserDataLoadedState extends AppStates {}

class AppAddCategoryErrorState extends AppStates {
  final String categoryName;
  AppAddCategoryErrorState(this.categoryName);
}
class AppAddCategorySuccessState extends AppStates {
  final String categoryName;
  AppAddCategorySuccessState(this.categoryName);
}


class AppCategoriesLoadedState extends AppStates {
  final String categoryName;
  AppCategoriesLoadedState(this.categoryName);
}
class AppBottomNavChangedState extends AppStates {}
class AppCartChangedState extends AppStates {}

class AppProfileImagePickedState extends AppStates {}
class AppCoverImagePickedState extends AppStates {}

class AppUpdateProfileLoadingState extends AppStates {}
class AppUpdateProfileSuccessState extends AppStates {}
class AppUpdateProfileErrorState extends AppStates {
  final String message;
  AppUpdateProfileErrorState(this.message);
}

class AppChangePasswordLoadingState extends AppStates {}
class AppChangePasswordSuccessState extends AppStates {}
class AppChangePasswordErrorState extends AppStates {
  final String message;
  AppChangePasswordErrorState(this.message);
}

class AppLanguageChangedState extends AppStates {}
class AppLanguageErrorState extends AppStates {
  final String message;
  AppLanguageErrorState(this.message);

}

class AppSearchState extends AppStates {}

class AppCreateOrderLoadingState extends AppStates {}
class AppCreateOrderSuccessState extends AppStates {}
class AppCreateOrderErrorState extends AppStates {
  final String message;
  AppCreateOrderErrorState(this.message);
}


