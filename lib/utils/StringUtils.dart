class StringUtils {
  static String enforceMaxLength(String value, int maxLength) {
    if (value.length > maxLength) {
      return '${value.substring(0, maxLength)}...';
    }
    return value;
  }
}