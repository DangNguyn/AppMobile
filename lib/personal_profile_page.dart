import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_service.dart';

const _profileBlue = Color(0xFF1B6EEB);
const _profileNavy = Color(0xFF0E1F38);

class PersonalProfilePage extends StatefulWidget {
  const PersonalProfilePage({
    super.key,
    required this.fullName,
    required this.username,
  });

  final String fullName;
  final String username;

  @override
  State<PersonalProfilePage> createState() => _PersonalProfilePageState();
}

class _PersonalProfilePageState extends State<PersonalProfilePage> {
  final _picker = ImagePicker();
  final _searchController = TextEditingController();
  final List<_ProfilePost> _posts = [];
  String? _avatarPath;
  bool _privateProfile = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
    _loadAvatar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacy() async {
    final isPrivate = await userService.getPrivateProfilePref();
    if (mounted) setState(() => _privateProfile = isPrivate);
  }

  Future<void> _loadAvatar() async {
    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString('personal_profile_avatar_path');
    if (mounted && path != null) setState(() => _avatarPath = path);
  }

  Future<void> _chooseAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1400,
    );
    if (image != null && mounted) {
      setState(() => _avatarPath = image.path);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('personal_profile_avatar_path', image.path);
    }
  }

  Future<void> _openPrivacy() async {
    final value = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProfilePrivacyPage(initialValue: _privateProfile),
      ),
    );
    if (value != null && mounted) {
      setState(() => _privateProfile = value);
    } else if (mounted) {
      await _loadPrivacy();
    }
  }

  Future<void> _createPost() async {
    final result = await Navigator.of(context).push<_ProfilePost>(
      MaterialPageRoute<_ProfilePost>(
        builder: (_) => _CreatePostPage(picker: _picker),
      ),
    );
    if (result != null && mounted) setState(() => _posts.insert(0, result));
  }

  Future<void> _deletePost(_ProfilePost post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text('Bài viết này sẽ bị xóa khỏi hồ sơ của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      setState(() => _posts.remove(post));
    }
  }

  String get _initials {
    final parts = widget.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.first.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: _profileNavy,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: Text(
              widget.username,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const BackButton(),
            actions: [
              IconButton(
                tooltip: 'Cài đặt quyền riêng tư',
                onPressed: _openPrivacy,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(62),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  height: 48,
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Tìm trang cá nhân',
                    leading: const Icon(Icons.search_rounded),
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    elevation: WidgetStateProperty.all(0),
                    onSubmitted: (_) => _showSearchMessage(),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: _buildProfileCard(),
            ),
          ),
          if (_privateProfile)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4DF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF9A6817)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hồ sơ của bạn đang ở chế độ riêng tư.',
                        style: TextStyle(color: _profileNavy),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                      child: _ProfileStat(
                          value: '${_posts.length}', label: 'Bài viết')),
                  const Expanded(
                      child: _ProfileStat(value: '—', label: 'Đánh giá')),
                  Expanded(
                    child: _ProfileStat(
                      value:
                          '${_posts.where((post) => post.imagePath != null).length}',
                      label: 'Hình ảnh',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 10),
              color: Colors.white,
              child: const Text(
                'Bài viết',
                style: TextStyle(
                  color: _profileBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (_posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(30, 26, 30, 90),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.travel_explore_rounded,
                        size: 78, color: Color(0xFFBDE8FC)),
                    SizedBox(height: 18),
                    Text(
                      'Chia sẻ bài viết đầu tiên của bạn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF65717D),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kể về chuyến đi hoặc khoảnh khắc đáng nhớ của bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7C8793), height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) => _PostCard(
                post: _posts[index],
                name: widget.fullName,
                avatarPath: _avatarPath,
                onDelete: () => _deletePost(_posts[index]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tạo bài viết',
        onPressed: _createPost,
        backgroundColor: _profileBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFE7F2FF),
                      foregroundImage: _avatarPath == null
                          ? null
                          : FileImage(File(_avatarPath!)),
                      child: _avatarPath == null
                          ? Text(_initials,
                              style: const TextStyle(
                                  color: _profileNavy,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800))
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: _profileBlue,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _chooseAvatar,
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 17),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.fullName,
                          style: const TextStyle(
                              color: _profileNavy,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('@${widget.username}',
                          style: const TextStyle(color: Color(0xFF75818E))),
                      TextButton.icon(
                        onPressed: _chooseAvatar,
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: _profileBlue),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Đổi ảnh đại diện'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text(
            'Tìm kiếm tài khoản sẽ được kết nối khi có dữ liệu người dùng.'),
      ));
  }
}

class ProfilePrivacyPage extends StatefulWidget {
  const ProfilePrivacyPage({super.key, required this.initialValue});

  final bool initialValue;

  @override
  State<ProfilePrivacyPage> createState() => _ProfilePrivacyPageState();
}

class _ProfilePrivacyPageState extends State<ProfilePrivacyPage> {
  late bool _private = widget.initialValue;

  Future<void> _setPrivate(bool value) async {
    setState(() => _private = value);
    await userService.savePrivateProfilePref(value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          backgroundColor: _profileNavy,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading:
              BackButton(onPressed: () => Navigator.pop(context, _private)),
          title: const Text('Quyền riêng tư'),
        ),
        body: ListView(
          children: [
            _PrivacyOption(
              title: 'Đặt hồ sơ thành riêng tư',
              description:
                  'Khi bật chế độ này, người khác sẽ không thể xem hồ sơ và bài viết của bạn.',
              value: _private,
              onChanged: _setPrivate,
            ),
          ],
        ),
      );
}

class _PrivacyOption extends StatelessWidget {
  const _PrivacyOption({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 20, 14, 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _profileNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(description,
                      style: const TextStyle(
                          color: Color(0xFF778390), height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: _profileNavy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Color(0xFF7C8792))),
        ],
      );
}

class _ProfilePost {
  const _ProfilePost({
    required this.caption,
    this.imagePath,
    this.location = '',
    this.hashtags = const [],
  });

  final String caption;
  final String? imagePath;
  final String location;
  final List<String> hashtags;
}

class _CreatePostPage extends StatefulWidget {
  const _CreatePostPage({required this.picker});

  final ImagePicker picker;

  @override
  State<_CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<_CreatePostPage> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _hashtagController = TextEditingController();
  final List<String> _hashtags = [];
  String? _imagePath;

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await widget.picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (image != null && mounted) setState(() => _imagePath = image.path);
  }

  void _publish() {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) return;
    Navigator.of(context).pop(
      _ProfilePost(
        caption: caption,
        imagePath: _imagePath,
        location: _locationController.text.trim(),
        hashtags: List.unmodifiable(_hashtags),
      ),
    );
  }

  Future<void> _addHashtag() async {
    _hashtagController.clear();
    final tag = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm hashtag'),
        content: TextField(
          controller: _hashtagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ví dụ: DaLat'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _hashtagController.text),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    final cleanTag = (tag ?? '').trim().replaceAll(RegExp(r'^#+'), '');
    if (cleanTag.isNotEmpty && !_hashtags.contains(cleanTag) && mounted) {
      setState(() => _hashtags.add(cleanTag));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = _captionController.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _profileNavy,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Tạo bài viết',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: Color(0xFF20252B),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(text: 'Chú thích'),
                        TextSpan(
                            text: ' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 210,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PhotoPickerTile(
                          imagePath: _imagePath,
                          onTap: _pickPhoto,
                          onRemove: () => setState(() => _imagePath = null),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            autofocus: true,
                            expands: true,
                            maxLines: null,
                            maxLength: 2000,
                            textAlignVertical: TextAlignVertical.top,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              hintText:
                                  '💡 Gợi ý cho chú thích của bạn:\n🌍 Tên điểm đến và vị trí —\n😍 Điều gì thú vị ở đây? —\n🚗 Làm thế nào để đi đến đó?',
                              hintStyle: TextStyle(
                                color: Color(0xFFB3BAC2),
                                height: 1.45,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_captionController.text.length}/2000',
                      style: const TextStyle(color: Color(0xFF9AA2AA)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addHashtag,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: const Color(0xFF2A6EEB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.tag_rounded),
                    label: const Text('Thêm hashtag'),
                  ),
                  if (_hashtags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final tag in _hashtags)
                          InputChip(
                            label: Text('#$tag'),
                            onDeleted: () =>
                                setState(() => _hashtags.remove(tag)),
                          ),
                      ],
                    ),
                  const SizedBox(height: 28),
                  const Text(
                    'Có gì trong bài viết này?',
                    style: TextStyle(
                      color: Color(0xFF20252B),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Gắn thẻ địa danh, mục hoặc điểm đến',
                      hintStyle: TextStyle(color: Color(0xFFADB4BC)),
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF818A93),
                        height: 1.4,
                        fontSize: 14,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Khi đăng bài viết này, bạn đồng ý với Điều khoản và Chính sách quyền riêng tư của ',
                        ),
                        const TextSpan(
                          text: 'FomoGO',
                          style: TextStyle(
                            color: Color(0xFF2A6EEB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE9EDF1))),
              ),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  onPressed: canPublish ? _publish : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6EEB),
                    disabledBackgroundColor: const Color(0xFFE9EBEF),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF9AA0A6),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Đăng bài viết',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPickerTile extends StatelessWidget {
  const _PhotoPickerTile({
    required this.imagePath,
    required this.onTap,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 118,
        height: 190,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: const Color(0xFF2A6EEB)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imagePath == null)
                      const Center(
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: Color(0xFF1674C5),
                          size: 42,
                        ),
                      )
                    else
                      Image.file(File(imagePath!), fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: const Color(0xFF2A6EEB),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: imagePath == null ? onTap : onRemove,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              imagePath == null ? Icons.add : Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 14.0;
    const dashWidth = 6.0;
    const gap = 5.0;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(radius),
      ));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.name,
    required this.avatarPath,
    required this.onDelete,
  });

  final _ProfilePost post;
  final String name;
  final String? avatarPath;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE7F2FF),
                    foregroundImage: avatarPath == null
                        ? null
                        : FileImage(File(avatarPath!)),
                    child: avatarPath == null
                        ? const Icon(Icons.person, color: _profileNavy)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            color: _profileNavy, fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.public_rounded,
                      color: Color(0xFF788490), size: 18),
                  PopupMenuButton<String>(
                    tooltip: 'Tùy chọn bài viết',
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Xóa bài viết'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (post.caption.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(post.caption, style: const TextStyle(height: 1.4)),
              ],
              if (post.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        color: _profileBlue, size: 18),
                    const SizedBox(width: 4),
                    Text(post.location,
                        style: const TextStyle(color: _profileBlue)),
                  ],
                ),
              ],
              if (post.hashtags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final tag in post.hashtags)
                      Text('#$tag',
                          style: const TextStyle(
                              color: _profileBlue,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              if (post.imagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(post.imagePath!),
                      height: 240, fit: BoxFit.cover),
                ),
              ],
            ],
          ),
        ),
      );
}
