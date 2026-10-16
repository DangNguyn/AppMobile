part of 'booking_app.dart';

class BrandOfferSection extends StatelessWidget {
  const BrandOfferSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ưu đãi thương hiệu 10.10',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 138,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                SizedBox(
                  width: 130,
                  child: BrandOfferCard(
                    color: Color(0xFFD7C298),
                    title: 'MƯỜNG THANH',
                    discount: '20%',
                  ),
                ),
                SizedBox(width: 14),
                SizedBox(
                  width: 130,
                  child: BrandOfferCard(
                    color: Color(0xFFE5D4A6),
                    title: 'HANOI BLISS',
                    discount: '20%',
                  ),
                ),
                SizedBox(width: 14),
                SizedBox(
                  width: 130,
                  child: BrandOfferCard(
                    color: Color(0xFF3F78D7),
                    title: 'HOTELS & RESORTS',
                    discount: '40%',
                  ),
                ),
                SizedBox(width: 14),
                SizedBox(
                  width: 130,
                  child: BrandOfferCard(
                    color: Color(0xFF59A88A),
                    title: 'MELIÁ HOTELS',
                    discount: '30%',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BrandOfferCard extends StatelessWidget {
  final Color color;
  final String title;
  final String discount;

  const BrandOfferCard({
    super.key,
    required this.color,
    required this.title,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Giảm đến',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            discount,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoverBanner extends StatelessWidget {
  const DiscoverBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vô vàn ưu đãi khác',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD8D4A8), Color(0xFFB8C480)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 22,
                      left: 30,
                      right: 30,
                      bottom: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 18,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 36,
                      bottom: 50,
                      child: Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9D864),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Du lịch',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0E3A91),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Úc',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0E3A91),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Giảm đến',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0E3A91),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '50%',
                      style: TextStyle(
                        fontSize: 36,
                        color: Color(0xFF0E3A91),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ScrollTopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ScrollTopButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EBF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Lên đầu trang',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A6EEB),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
