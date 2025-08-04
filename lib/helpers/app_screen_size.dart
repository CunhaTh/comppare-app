import 'dart:ui';

class AppScreenSize {
  static final PlatformDispatcher _platformDispatcher =
      PlatformDispatcher.instance;

  // Largura em pixels lógicos
  static double get width =>
      _platformDispatcher.views.first.physicalSize.width /
      _platformDispatcher.views.first.devicePixelRatio;

  // Altura em pixels lógicos
  static double get height =>
      _platformDispatcher.views.first.physicalSize.height /
      _platformDispatcher.views.first.devicePixelRatio;

  // Proporção de pixels (DPR)
  static double get pixelRatio =>
      _platformDispatcher.views.first.devicePixelRatio;

  // Pixels físicos
  static double get physicalWidth =>
      _platformDispatcher.views.first.physicalSize.width;

  static double get physicalHeight =>
      _platformDispatcher.views.first.physicalSize.height;
}
