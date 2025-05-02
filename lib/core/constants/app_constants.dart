class AppConstants {
  static final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_.-]{3,20}$');
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[a-zA-Z]{2,}$');
  static final RegExp passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{6,}$');
  static final RegExp nameRegex = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ\s]{3,}$');
  static final RegExp surnameRegex = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ\s]{3,}$');
  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{9,14}$');
  static final RegExp addressRegex = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ0-9\s,.-]{5,}$');
}
