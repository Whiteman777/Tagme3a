import '../domain/entities/onboarding_slide.dart';

const onboardingSlides = <OnboardingSlide>[
  OnboardingSlide(
    title: 'قارن الأسعار في مكان واحد',
    body: 'شوف أسعار القطع من المتاجر المصرية، وقارن قبل ما تشتري.',
    imageAsset: 'assets/images/gpu.jpg',
    stepLabel: '١ من ٣',
  ),
  OnboardingSlide(
    title: 'اتأكد إن القطع متوافقة',
    body: 'تجميعة بتفحص المعالج واللوحة والرامات، وبتنبّهك لأي تعارض.',
    imageAsset: 'assets/images/motherboard.jpg',
    stepLabel: '٢ من ٣',
  ),
  OnboardingSlide(
    title: 'ما تفوّتش أفضل سعر',
    body: 'فعّل تنبيهات الأسعار، ووصلّك إشعار أول ما السعر ينزل.',
    imageAsset: 'assets/images/laptop.jpg',
    stepLabel: '٣ من ٣',
  ),
];
