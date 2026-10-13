import 'package:flutter/material.dart';

const _navy = Color(0xFF0E1F38);
const _blue = Color(0xFF2A6EEB);
const _paleBlue = Color(0xFFE8F1FF);

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
    required this.savedArticleTitles,
    required this.onToggleSaved,
  });

  final Set<String> savedArticleTitles;
  final ValueChanged<TravelArticle> onToggleSaved;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRegion = 'Tất cả';

  static const _regions = ['Tất cả', 'Miền Bắc', 'Miền Trung', 'Miền Nam'];

  List<TravelArticle> get _filteredArticles {
    return _travelArticles.where((article) {
      final matchesQuery = _searchQuery.isEmpty ||
          '${article.title} ${article.location} ${article.description}'
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesRegion =
          _selectedRegion == 'Tất cả' || article.region == _selectedRegion;
      return matchesQuery && matchesRegion;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectRegion() async {
    final region = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lọc theo khu vực',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ..._regions.map(
                (region) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(region),
                  trailing: _selectedRegion == region
                      ? const Icon(Icons.check_circle, color: _blue)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () => Navigator.pop(context, region),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (region != null) {
      setState(() => _selectedRegion = region);
    }
  }

  void _shareArticle(TravelArticle article) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Chia sẻ bài viết: ${article.title}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final articles = _filteredArticles;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            18,
            MediaQuery.of(context).padding.top + 12,
            18,
            20,
          ),
          decoration: const BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Khám phá Việt Nam',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cảm hứng cho chuyến đi tiếp theo của bạn',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value.trim()),
                      decoration: InputDecoration(
                        hintText: 'Tìm danh lam, thành phố Việt Nam...',
                        hintStyle: const TextStyle(color: Color(0xFF858B94)),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF6E7783),
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Xóa tìm kiếm',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(
                      tooltip: 'Lọc khu vực',
                      onPressed: _selectRegion,
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text(
                      'DANH LAM VIỆT NAM NỔI BẬT',
                      style: TextStyle(
                        color: Color(0xFF17202C),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Text(
                    '${articles.length} bài viết',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (_selectedRegion != 'Tất cả') ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(_selectedRegion),
                    onDeleted: () => setState(() => _selectedRegion = 'Tất cả'),
                    deleteIconColor: _blue,
                    backgroundColor: _paleBlue,
                    labelStyle: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (articles.isEmpty)
                const _EmptySearchResult()
              else
                ...articles.map(
                  (article) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _TravelArticleCard(
                      article: article,
                      isSaved:
                          widget.savedArticleTitles.contains(article.title),
                      onSave: () => widget.onToggleSaved(article),
                      onShare: () => _shareArticle(article),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TravelArticleDetailPage(article: article),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TravelArticleCard extends StatelessWidget {
  const _TravelArticleCard({
    required this.article,
    required this.isSaved,
    required this.onSave,
    required this.onShare,
    required this.onTap,
  });

  final TravelArticle article;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: const Color(0x1A0E1F38),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 164,
          child: Row(
            children: [
              SizedBox(
                width: 142,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const _ArticleImageFallback(),
                      errorBuilder: (context, error, stackTrace) =>
                          const _ArticleImageFallback(),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 15,
                                color: _blue,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  article.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF27303B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF17202C),
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          article.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF58616D),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: _blue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              article.readTime,
                              style: const TextStyle(
                                color: Color(0xFF66707D),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip:
                                isSaved ? 'Bỏ lưu bài viết' : 'Lưu bài viết',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 34,
                              height: 34,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: onSave,
                            icon: Icon(
                              isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: isSaved ? _blue : const Color(0xFF303943),
                              size: 21,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Chia sẻ bài viết',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 34,
                              height: 34,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: onShare,
                            icon: const Icon(
                              Icons.share_outlined,
                              color: Color(0xFF303943),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleImageFallback extends StatelessWidget {
  const _ArticleImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB9DDF5), Color(0xFF4E95C4), Color(0xFF1C4F75)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(Icons.landscape_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          const Icon(Icons.travel_explore, color: _blue, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Chưa tìm thấy bài viết phù hợp',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'Thử tìm bằng tên địa điểm khác nhé.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.56)),
          ),
        ],
      ),
    );
  }
}

class TravelArticleDetailPage extends StatelessWidget {
  const TravelArticleDetailPage({super.key, required this.article});

  final TravelArticle article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ArticleImageFallback(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            sliver: SliverList.list(
              children: [
                Text(
                  article.region.toUpperCase(),
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _blue,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      article.location,
                      style: const TextStyle(
                        color: Color(0xFF66707D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.schedule_rounded,
                      color: _blue,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      article.readTime,
                      style: const TextStyle(color: Color(0xFF66707D)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  article.description,
                  style: const TextStyle(
                    color: Color(0xFF27303B),
                    fontSize: 16,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  article.story,
                  style: const TextStyle(
                    color: Color(0xFF4E5864),
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),
                _ArticleGallery(imageUrls: article.galleryImageUrls),
                const SizedBox(height: 28),
                ...article.sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _ArticleSectionView(section: section),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F7FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, color: _blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mẹo nhỏ: ${article.travelTip}',
                          style: const TextStyle(
                            color: Color(0xFF34445A),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chọn khám phá ${article.location}'),
                    ),
                  ),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text(
                    'Khám phá điểm đến',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleGallery extends StatelessWidget {
  const _ArticleGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình ảnh điểm đến',
          style: TextStyle(
            color: _navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrls[index],
                width: 220,
                height: 150,
                fit: BoxFit.cover,
                semanticLabel: 'Ảnh minh họa ${index + 1} của điểm đến',
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 220,
                  child: _ArticleImageFallback(),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        width: 220,
                        child: _ArticleImageFallback(),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArticleSectionView extends StatelessWidget {
  const _ArticleSectionView({required this.section});

  final ArticleSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading,
          style: const TextStyle(
            color: _navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.body,
          style: const TextStyle(
            color: Color(0xFF4E5864),
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

class TravelArticle {
  const TravelArticle({
    required this.title,
    required this.location,
    required this.region,
    required this.description,
    required this.readTime,
    required this.imageUrl,
    required this.story,
    required this.galleryImageUrls,
    required this.sections,
    required this.travelTip,
  });

  final String title;
  final String location;
  final String region;
  final String description;
  final String readTime;
  final String imageUrl;
  final String story;
  final List<String> galleryImageUrls;
  final List<ArticleSection> sections;
  final String travelTip;
}

class ArticleSection {
  const ArticleSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

const _travelArticles = [
  TravelArticle(
    title: 'Kỳ quan thiên nhiên: Vịnh Hạ Long',
    location: 'Hạ Long, Quảng Ninh',
    region: 'Miền Bắc',
    description:
        'Du ngoạn du thuyền, khám phá hang động kỳ bí giữa làn nước xanh ngọc.',
    readTime: '5 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=720&q=85',
    story:
        'Hàng nghìn đảo đá vôi nhấp nhô giữa mặt biển tạo nên một khung cảnh khó quên. Hãy dành thời gian đi thuyền qua các hang động, ngắm hoàng hôn trên vịnh và thưởng thức hải sản địa phương.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Ngắm vịnh từ mặt nước',
        body:
            'Một chuyến du thuyền giúp bạn nhìn gần những đảo đá mang hình dáng độc đáo, ghé hang Sửng Sốt hoặc chèo kayak ở vùng nước yên. Nếu có thời gian, hãy chọn hành trình qua đêm để ngắm bình minh trên vịnh.',
      ),
      ArticleSection(
        heading: 'Một ngày khám phá Hạ Long',
        body:
            'Buổi sáng lên tàu từ bến, giữa ngày tham quan hang động và nghỉ ngơi trên boong. Cuối buổi chiều, ngắm nắng dịu trên mặt biển rồi thưởng thức chả mực và hải sản địa phương tại thành phố Hạ Long.',
      ),
    ],
    travelTip:
        'Đặt trước vé tàu vào dịp cao điểm, mang áo khoác nhẹ và kiểm tra dự báo thời tiết trước khi khởi hành.',
  ),
  TravelArticle(
    title: 'Đảo ngọc Phú Quốc: Biển xanh cát trắng',
    location: 'Phú Quốc, Kiên Giang',
    region: 'Miền Nam',
    description:
        'Lặn ngắm san hô, tận hưởng hoàng hôn rực rỡ trên những bãi biển trong veo.',
    readTime: '4 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=720&q=85',
    story:
        'Phú Quốc quyến rũ với bờ cát mềm, làn nước ấm và nhịp sống thư thái. Bạn có thể khám phá các đảo nhỏ bằng thuyền, lặn ngắm san hô rồi khép lại ngày dài bằng khoảnh khắc mặt trời lặn trên biển.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Biển đảo và những buổi chiều yên ả',
        body:
            'Bãi Sao nổi bật với bờ cát sáng màu, còn quần đảo An Thới là lựa chọn cho chuyến đi thuyền và lặn ngắm san hô. Khi chiều xuống, tìm một góc ở bờ biển phía tây để ngắm mặt trời dần khuất sau đường chân trời.',
      ),
      ArticleSection(
        heading: 'Thưởng thức vị biển đảo',
        body:
            'Chợ đêm Phú Quốc có nhiều món ăn địa phương để thử sau một ngày ngoài biển. Nước mắm, hồ tiêu và hải sản là những đặc sản thường được du khách chọn mua; hãy ưu tiên cơ sở có nguồn gốc và giá niêm yết rõ ràng.',
      ),
    ],
    travelTip:
        'Mùa khô thường thuận tiện cho hoạt động ngoài trời; nhớ dùng kem chống nắng và chọn tour biển có trang bị an toàn.',
  ),
  TravelArticle(
    title: 'Dấu ấn hoài cổ: Phố cổ Hội An',
    location: 'Hội An, Quảng Nam',
    region: 'Miền Trung',
    description:
        'Khám phá phố đèn lồng, thưởng thức ẩm thực đường phố và nét duyên bên sông Hoài.',
    readTime: '6 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=720&q=85',
    story:
        'Những mái nhà vàng, con phố nhỏ và sắc đèn lồng khiến Hội An đẹp như một thước phim. Dạo phố lúc chiều muộn, ghé một hàng cao lầu và ngồi thuyền trên sông Hoài là những trải nghiệm rất đáng thử.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Dạo bước giữa phố cổ',
        body:
            'Bắt đầu từ những con đường quanh Chùa Cầu, ghé các hội quán và ngôi nhà cổ để tìm hiểu dấu ấn giao thương xưa. Khi đèn lồng được thắp lên, bờ sông Hoài trở thành nơi lý tưởng để ngắm phố và chụp ảnh.',
      ),
      ArticleSection(
        heading: 'Thưởng thức món ngon Hội An',
        body:
            'Cao lầu, mì Quảng và bánh mì là những món ăn được nhiều người yêu thích. Bạn có thể thong thả đi bộ giữa các điểm tham quan, dừng ở quán nhỏ trong phố và dành thêm thời gian cho các làng nghề quanh khu đô thị cổ.',
      ),
    ],
    travelTip:
        'Phố cổ đẹp nhất vào sáng sớm hoặc lúc lên đèn; nên đi bộ, mang giày thoải mái và tôn trọng quy định tại di tích.',
  ),
  TravelArticle(
    title: 'Chạm đến mây trời: Bà Nà Hills & Cầu Vàng',
    location: 'Đà Nẵng',
    region: 'Miền Trung',
    description:
        'Chiêm ngưỡng cây cầu giữa mây trời và khung cảnh núi rừng từ cáp treo.',
    readTime: '5 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=720&q=85',
    story:
        'Từ trên cao, Cầu Vàng mở ra tầm nhìn rộng lớn giữa núi non và mây trắng. Một ngày ở Bà Nà có thể kết hợp đi cáp treo, dạo vườn hoa và nghỉ chân tại những góc ngắm cảnh trên đỉnh núi.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Tản bộ trên Cầu Vàng',
        body:
            'Cây cầu uốn cong giữa sườn núi, với đôi bàn tay đá nâng lối đi trên cao. Hãy thong thả ngắm toàn cảnh núi rừng từ lan can và dành thời gian khám phá các khu vườn, quảng trường trên đỉnh Bà Nà.',
      ),
      ArticleSection(
        heading: 'Lên lịch cho chuyến đi',
        body:
            'Từ trung tâm Đà Nẵng, bạn có thể đi xe đến khu du lịch rồi tiếp tục bằng cáp treo. Nên đến sớm để có thời gian trải nghiệm các điểm tham quan, theo dõi giờ hoạt động cáp treo và chuẩn bị áo khoác vì thời tiết trên núi có thể mát hơn.',
      ),
    ],
    travelTip:
        'Kiểm tra lịch vận hành và dự báo thời tiết trước ngày đi; buổi sáng thường dễ có tầm nhìn thoáng hơn.',
  ),
  TravelArticle(
    title: 'Sa Pa sương mù: Vẻ đẹp ruộng bậc thang',
    location: 'Sa Pa, Lào Cai',
    region: 'Miền Bắc',
    description:
        'Chiêm ngưỡng ruộng bậc thang uốn lượn và những bản làng ẩn hiện trong mây.',
    readTime: '7 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=720&q=85',
    story:
        'Sa Pa thay đổi sắc màu theo mùa lúa, từ xanh non đến vàng óng trên sườn núi. Đi bộ qua các bản làng, gặp gỡ người dân địa phương và thức dậy giữa biển mây sẽ đem đến một chuyến đi đậm chất vùng cao.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Theo dấu những thửa ruộng bậc thang',
        body:
            'Các cung đường quanh Mường Hoa mở ra tầm nhìn xuống thung lũng và những bản làng nép bên sườn núi. Mùa nước đổ và mùa lúa chín đều có nét đẹp riêng; đi bộ cùng hướng dẫn viên địa phương giúp chuyến trekking an toàn và nhiều trải nghiệm hơn.',
      ),
      ArticleSection(
        heading: 'Chạm vào nhịp sống vùng cao',
        body:
            'Dành thời gian ghé bản Cát Cát hoặc Tả Van, tìm hiểu nghề thủ công và nghỉ lại homestay để cảm nhận buổi sáng trong lành. Nếu thời tiết thuận lợi, bạn có thể kết hợp hành trình với núi Fansipan và các điểm ngắm cảnh trong thị trấn.',
      ),
    ],
    travelTip:
        'Địa hình dốc và thời tiết thay đổi nhanh; hãy mang giày bám tốt, áo mưa mỏng và hỏi đường trước khi trekking.',
  ),
  TravelArticle(
    title: 'Sài Gòn không ngủ: Nhịp sống giữa lòng thành phố',
    location: 'TP. Hồ Chí Minh',
    region: 'Miền Nam',
    description:
        'Dạo phố trung tâm, ngắm những công trình biểu tượng và khám phá thiên đường ẩm thực.',
    readTime: '6 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=720&q=85',
    story:
        'Thành phố Hồ Chí Minh cuốn hút bởi sự giao thoa giữa những con phố nhộn nhịp, kiến trúc xưa và các tòa nhà hiện đại. Bắt đầu ngày mới ở khu trung tâm, ghé chợ Bến Thành, dừng chân thưởng thức cà phê rồi khám phá ẩm thực đường phố khi thành phố lên đèn.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Một vòng những dấu ấn thành phố',
        body:
            'Khu trung tâm là nơi thuận tiện để kết nối chợ Bến Thành, phố đi bộ Nguyễn Huệ và các công trình kiến trúc lâu đời. Dành thời gian ghé một bảo tàng hoặc quán cà phê trong hẻm để cảm nhận thêm những lát cắt khác nhau của Sài Gòn.',
      ),
      ArticleSection(
        heading: 'Thành phố lên đèn',
        body:
            'Khi trời tối, các tuyến phố ẩm thực và khu vực ven sông trở nên nhộn nhịp. Thử một bữa ăn đường phố, ngắm đường chân trời từ một điểm nhìn công cộng và ưu tiên phương tiện di chuyển an toàn khi về muộn.',
      ),
    ],
    travelTip:
        'Nắng và mưa rào có thể đến nhanh; mang nước, áo mưa gọn nhẹ và dùng ứng dụng bản đồ để chọn tuyến đường phù hợp.',
  ),
  TravelArticle(
    title: 'Nha Trang: Hẹn nhau bên vịnh biển xanh',
    location: 'Nha Trang, Khánh Hòa',
    region: 'Miền Trung',
    description:
        'Tận hưởng bãi biển trong xanh, đi thuyền khám phá đảo và thưởng thức hải sản miền biển.',
    readTime: '5 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=720&q=85',
    story:
        'Nha Trang là điểm hẹn lý tưởng cho những ngày muốn sống chậm bên biển. Bạn có thể dành buổi sáng trên bãi cát, tham gia chuyến tàu ra các đảo trong vịnh và kết thúc một ngày đầy nắng bằng bữa hải sản tươi ngon.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Khám phá vịnh Nha Trang',
        body:
            'Một chuyến tham quan vịnh có thể đưa bạn đến các đảo, bãi tắm và điểm ngắm cảnh ven biển. Hãy chọn đơn vị tổ chức có áo phao và hướng dẫn rõ ràng; nếu thích nghỉ ngơi, bãi biển trung tâm cũng đủ cho một buổi sáng thư thái.',
      ),
      ArticleSection(
        heading: 'Thành phố biển qua những hương vị',
        body:
            'Nem nướng, bún cá và hải sản là những món đáng thử khi ghé Nha Trang. Sau buổi tắm biển, dạo dọc đường Trần Phú hoặc ghé tháp Bà Ponagar để kết hợp cảnh quan biển với dấu tích văn hóa Chăm.',
      ),
    ],
    travelTip:
        'Chọn hoạt động biển theo điều kiện sóng gió trong ngày, hỏi rõ giá dịch vụ và luôn mặc áo phao khi đi thuyền.',
  ),
  TravelArticle(
    title: 'Hà Nội: Một vòng phố cổ và hương vị thủ đô',
    location: 'Hà Nội',
    region: 'Miền Bắc',
    description:
        'Tản bộ quanh hồ Gươm, khám phá phố cổ và thưởng thức những món ngon đất Hà Thành.',
    readTime: '6 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=720&q=85',
    story:
        'Hà Nội đẹp trong những con phố nhỏ, hàng cây rợp bóng và nhịp sống bình dị quanh hồ Gươm. Hãy dành thời gian ghé phố cổ, thưởng thức phở nóng, bún chả hay cà phê trứng để cảm nhận trọn vẹn hương vị của thủ đô.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Từ hồ Gươm đến những con phố cũ',
        body:
            'Bắt đầu buổi sáng quanh hồ Hoàn Kiếm, ghé đền Ngọc Sơn rồi tiếp tục đi bộ qua những con phố của khu phố cổ. Mỗi tuyến phố lưu giữ một nhịp sống riêng, từ cửa hàng thủ công đến quán ăn gia truyền.',
      ),
      ArticleSection(
        heading: 'Nếm thử hương vị Hà Nội',
        body:
            'Một bát phở buổi sáng, bún chả cho bữa trưa hay cà phê trứng trong một quán nhỏ là những trải nghiệm giản dị mà đáng nhớ. Nếu còn thời gian, hãy ghé Văn Miếu hoặc khu vực quanh hồ Tây để đổi không khí.',
      ),
    ],
    travelTip:
        'Cuối tuần, một số tuyến phố quanh hồ Gươm dành cho người đi bộ; nên kiểm tra giờ hoạt động và chuẩn bị giày dễ đi.',
  ),
  TravelArticle(
    title: 'Đà Lạt mộng mơ: Thành phố của ngàn thông',
    location: 'Đà Lạt, Lâm Đồng',
    region: 'Miền Trung',
    description:
        'Săn mây buổi sớm, dạo rừng thông và nhâm nhi cà phê giữa tiết trời se lạnh.',
    readTime: '5 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=720&q=85',
    story:
        'Đà Lạt níu chân du khách bằng khí trời mát lành, những triền thông xanh và các con dốc yên bình. Thức dậy sớm để ngắm mây trôi trên đồi, ghé một quán cà phê nhỏ và dạo quanh hồ Xuân Hương sẽ làm nên chuyến đi thật thư thái.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Bình minh trên đồi thông',
        body:
            'Rời trung tâm từ sáng sớm để ghé một điểm ngắm mây hoặc dạo quanh hồ Tuyền Lâm, nơi rừng thông và mặt nước tạo nên khung cảnh yên bình. Buổi trưa có thể trở về thành phố, nghỉ ngơi và thưởng thức cà phê giữa tiết trời se lạnh.',
      ),
      ArticleSection(
        heading: 'Đi chậm giữa lòng Đà Lạt',
        body:
            'Hồ Xuân Hương, ga Đà Lạt và những con dốc quanh trung tâm phù hợp cho một buổi dạo bộ nhẹ nhàng. Nếu muốn ra ngoại ô, hãy sắp xếp phương tiện và thời gian hợp lý để ghé vườn hoa, thác nước hoặc các nông trại địa phương.',
      ),
    ],
    travelTip:
        'Sáng sớm và buổi tối thường lạnh hơn; mang áo ấm, kiểm tra đường đi và chỉ săn mây ở những địa điểm được phép.',
  ),
  TravelArticle(
    title: 'Cố đô Huế: Dấu xưa bên dòng sông Hương',
    location: 'Huế',
    region: 'Miền Trung',
    description:
        'Lắng nghe chuyện cung đình, thăm Đại Nội và thưởng thức nét tinh tế của ẩm thực Huế.',
    readTime: '7 phút đọc',
    imageUrl:
        'https://images.unsplash.com/photo-1561214115-f2f134cc4912?auto=format&fit=crop&w=720&q=85',
    story:
        'Huế mang vẻ trầm mặc của một kinh đô xưa với thành quách, lăng tẩm và dòng sông Hương êm đềm. Dạo bước trong Đại Nội, ghé thăm những khu vườn cổ và thưởng thức bún bò, bánh bèo hay chè Huế là cách tuyệt vời để hiểu thêm về vùng đất di sản này.',
    galleryImageUrls: [
      'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=720&q=85',
      'https://images.unsplash.com/photo-1561214115-f2f134cc4912?auto=format&fit=crop&w=720&q=85',
    ],
    sections: [
      ArticleSection(
        heading: 'Theo dấu di sản cố đô',
        body:
            'Dành nửa ngày để tham quan Đại Nội, từ Ngọ Môn đến các cung điện và khu vườn bên trong. Nếu lịch trình cho phép, hãy ghé một lăng tẩm triều Nguyễn; mỗi công trình có không gian và câu chuyện lịch sử riêng.',
      ),
      ArticleSection(
        heading: 'Một buổi chiều bên sông Hương',
        body:
            'Sau hành trình di sản, dạo qua cầu Trường Tiền và ngắm dòng sông lúc chiều muộn. Bữa ăn có thể bắt đầu với bún bò Huế, tiếp tục bằng bánh bèo, bánh nậm hoặc chè cung đình để cảm nhận nét phong phú của ẩm thực địa phương.',
      ),
    ],
    travelTip:
        'Nên dành đủ thời gian đi bộ trong khu di tích, mang nước và trang phục lịch sự khi tham quan các không gian thờ tự.',
  ),
];

List<TravelArticle> get allTravelArticles => _travelArticles;
