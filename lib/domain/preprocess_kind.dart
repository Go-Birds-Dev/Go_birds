/// Normalization applied before TFLite inference (must match training).
enum PreprocessKind {
  /// ImageNet mean subtraction in BGR order (VGG-style).
  vgg16MeanBGR,

  /// RGB scaled to [0, 1] (MobileNet-style; also used for DenseNet in this app).
  mobilenet255,
}
