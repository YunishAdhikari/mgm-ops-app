import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _floatController;

  final List<_FeatureItem> features = const [
    _FeatureItem('Reception', 'Check-ins & bookings', Icons.desk_rounded),
    _FeatureItem('Housekeeping', 'Rooms & cleaning status', Icons.cleaning_services_rounded),
    _FeatureItem('Maintenance', 'Issues & repairs', Icons.handyman_rounded),
    _FeatureItem('Restaurant', 'Bookings & service', Icons.restaurant_rounded),
    _FeatureItem('Attendance', 'QR clock-in system', Icons.qr_code_scanner_rounded),
  ];

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Animation<double> _fade(double start, double end) {
    return CurvedAnimation(
      parent: _mainController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _slide(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xff050505),
        body: Stack(
          children: [
            _background(),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fade(0.0, 0.35),
                      child: SlideTransition(
                        position: _slide(0.0, 0.35),
                        child: _logo(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    FadeTransition(
                      opacity: _fade(0.12, 0.55),
                      child: SlideTransition(
                        position: _slide(0.12, 0.55),
                        child: _heroSection(),
                      ),
                    ),

                    const SizedBox(height: 22),

                    FadeTransition(
                      opacity: _fade(0.28, 0.70),
                      child: const Text(
                        'Core Modules',
                        style: TextStyle(
                          color: Color(0xffa1a1aa),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: features.length,
                        itemBuilder: (context, index) {
                          final start = 0.32 + (index * 0.08);
                          final end = 0.75 + (index * 0.04);

                          return FadeTransition(
                            opacity: _fade(start, end.clamp(0.0, 1.0)),
                            child: SlideTransition(
                              position: _slide(start, end.clamp(0.0, 1.0)),
                              child: _featureCard(features[index]),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    FadeTransition(
                      opacity: _fade(0.70, 1.0),
                      child: _button(),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: TextButton(
                        onPressed: goToLogin,
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: Color(0xffd4d4d8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -130 + (_floatController.value * 25),
              right: -110,
              child: _glow(const Color(0xffdc2626), 310),
            ),
            Positioned(
              bottom: -160 - (_floatController.value * 20),
              left: -120,
              child: _glow(const Color(0xff7f1d1d), 340),
            ),
            Positioned(
              top: 150 + (_floatController.value * 14),
              right: -45,
              child: _hotelCard(),
            ),
          ],
        );
      },
    );
  }

  Widget _logo() {
    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffef4444), Color(0xff991b1b)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.35),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 13),
        const Text(
          'MGM Ops',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _heroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xffdc2626).withOpacity(0.14),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xffdc2626).withOpacity(0.30),
            ),
          ),
          child: const Text(
            'HOTEL OPERATIONS PLATFORM',
            style: TextStyle(
              color: Color(0xffff6b6b),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Run Every\nDepartment\nSmarter',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            height: 1.02,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'A modern internal app for reception, housekeeping, maintenance, restaurant bookings and attendance.',
          style: TextStyle(
            color: Color(0xffa1a1aa),
            fontSize: 15.5,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _featureCard(_FeatureItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xffdc2626).withOpacity(0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              item.icon,
              color: const Color(0xffff6b6b),
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xff71717a),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xff71717a),
            size: 15,
          ),
        ],
      ),
    );
  }

  Widget _button() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: goToLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffdc2626),
          elevation: 10,
          shadowColor: Colors.red.withOpacity(0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _hotelCard() {
    return Container(
      height: 170,
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Center(
        child: Icon(
          Icons.hotel_class_rounded,
          color: Colors.white.withOpacity(0.13),
          size: 82,
        ),
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.26),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _FeatureItem(this.title, this.subtitle, this.icon);
}