class ApiUtil {
  static Map<String, dynamic> selectAlbumImage(List images, int minDimension) {
    Map<String, dynamic> selected;
    for (final img in images) {
      if (img["height"] >= minDimension) {
        selected = Map.castFrom(img);
      }
    }
    if (selected == null) {
      selected = images[0];
    }
    return selected;
  }
}
