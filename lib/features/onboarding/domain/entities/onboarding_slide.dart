import 'package:equatable/equatable.dart';

class OnboardingSlide extends Equatable {
  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.imageAsset,
    required this.stepLabel,
  });

  final String title;
  final String body;
  final String imageAsset;
  final String stepLabel;

  @override
  List<Object?> get props => [title, body, imageAsset, stepLabel];
}
