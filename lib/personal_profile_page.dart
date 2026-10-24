import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_repository.dart';
import 'api/api_client.dart';
import 'api/models.dart';
import 'user_service.dart';
import 'privacy_settings_page.dart';

const _profileBlue = Color(0xFF1B6EEB);
const _profileNavy = Color(0xFF0E1F38);

class PersonalProfilePage extends StatefulWidget {
  const PersonalProfilePage({
    super.key,
    required this.fullName,
    required this.username,
    this.isOwner = false,
    this.profileIsPrivate,
    this.userId,
    this.avatarUrl,
  });

  final String fullName;
  final String username;

  /// Set to false when this page is opened by another account's profile search.
  final bool isOwner;

  /// Privacy value supplied by the profile owner when viewing someone else's page.
  /// Unknown profiles default to private so posts are never exposed by accident.
  final bool? profileIsPrivate;
  final String? userId;
  final String? avatarUrl;

  @override
  State<PersonalProfilePage> createState() => _PersonalProfilePageState();
}

class _PersonalProfilePageState extends State<PersonalProfilePage> {
  final _picker = ImagePicker();
  final _searchController = TextEditingController();
  List<ApiPost> _posts = const [];
  String? _avatarPath;
  bool _privateProfile = false;
  bool _privacyLoaded = false;
  bool _postsLoading = true;
  String? _postsError;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
    _loadAvatar();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacy() async {
    final isPrivate = widget.isOwner
        ? await userService.getPrivateProfilePref()
        : (widget.profileIsPrivate ?? true);
    if (mounted) {
      setState(() {
        _privateProfile = isPrivate;
        _privacyLoaded = true;
      });
    }
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacySettingsPage(),
      ),
    );
    if (mounted) await _loadPrivacy();
  }

  Future<void> _createPost() async {
    final draft = await Navigator.of(context).push<_PostDraft>(
      MaterialPageRoute<_PostDraft>(
        builder: (_) => const _CreatePostPage(),
      ),
    );
    if (draft == null || !mounted) return;
    try {
      await apiRepository.createPost(
        title: draft.title,
        location: draft.location,
        rating: 5,
        content: draft.content,
      );
      await _loadPosts();
      if (mounted) _showMessage('Đã đăng bài viết.');
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() {
      _postsLoading = true;
      _postsError = null;
    });
    try {
      final posts = widget.isOwner
          ? await apiRepository.myPosts()
          : (widget.userId == null
              ? <ApiPost>[]
              : await apiRepository.postsByUser(widget.userId!));
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _postsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _postsLoading = false;
        _postsError = _errorMessage(error);
      });
    }
  }

  Future<void> _deletePost(ApiPost post) async {
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
      try {
        await apiRepository.deletePost(post.id);
        await _loadPosts();
      } catch (error) {
        if (mounted) _showMessage(_errorMessage(error));
      }
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
    if (!widget.isOwner && !_privacyLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!widget.isOwner && _privateProfile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          backgroundColor: _profileNavy,
          foregroundColor: Colors.white,
          title: Text(widget.fullName),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 56, color: _profileBlue),
                SizedBox(height: 16),
                Text(
                  'Hồ sơ này đang ở chế độ riêng tư',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _profileNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bài viết và thông tin hồ sơ chỉ hiển thị với chủ tài khoản.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF75818E)),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
              widget.isOwner ? widget.username : widget.fullName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const BackButton(),
            actions: [
              if (widget.isOwner)
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
                    hintText: 'Tìm theo tên đầy đủ',
                    leading: const Icon(Icons.search_rounded),
                    trailing: [
                      if (_searching)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          tooltip: 'Tìm kiếm',
                          onPressed: _searchUsers,
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                    ],
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    elevation: WidgetStateProperty.all(0),
                    onSubmitted: (_) => _searchUsers(),
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
                      value: '0',
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
          if (_postsLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_postsError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_postsError!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadPosts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(30, 26, 30, 90),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.travel_explore_rounded,
                        size: 78, color: Color(0xFFBDE8FC)),
                    const SizedBox(height: 18),
                    Text(
                      widget.isOwner
                          ? 'Chia sẻ bài viết đầu tiên của bạn'
                          : 'Người dùng này chưa có bài viết công khai',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF65717D),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isOwner
                          ? 'Kể về chuyến đi hoặc khoảnh khắc đáng nhớ của bạn.'
                          : 'Các bài viết công khai của tài khoản sẽ hiển thị tại đây.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF7C8793), height: 1.4),
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
                name: _posts[index].authorName ?? widget.fullName,
                avatarPath: widget.isOwner ? _avatarPath : null,
                avatarUrl: widget.isOwner ? null : widget.avatarUrl,
                canDelete: widget.isOwner,
                onDelete: () => _deletePost(_posts[index]),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.isOwner
          ? FloatingActionButton(
              tooltip: 'Tạo bài viết',
              onPressed: _createPost,
              backgroundColor: _profileBlue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
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
                      foregroundImage: _profileAvatarImage(
                        widget.isOwner ? _avatarPath : null,
                        widget.isOwner ? null : widget.avatarUrl,
                      ),
                      child: (widget.isOwner
                              ? _avatarPath == null
                              : widget.avatarUrl == null)
                          ? Text(_initials,
                              style: const TextStyle(
                                  color: _profileNavy,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800))
                          : null,
                    ),
                    if (widget.isOwner)
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
                      if (widget.username.trim().isNotEmpty)
                        Text(
                          '@${widget.username.replaceFirst(RegExp(r'^@'), '')}',
                          style: const TextStyle(color: Color(0xFF75818E)),
                        )
                      else if (!widget.isOwner)
                        const Text(
                          'Username chưa được API cung cấp',
                          style: TextStyle(color: Color(0xFF75818E)),
                        ),
                      if (widget.isOwner)
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

  String _errorMessage(Object error) => error is ApiException
      ? error.message
      : 'Đã xảy ra lỗi. Vui lòng thử lại.';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;
    setState(() => _searching = true);
    try {
      final results = await apiRepository.searchUsers(query);
      if (!mounted) return;
      if (results.isEmpty) {
        _showMessage('Không tìm thấy tài khoản phù hợp.');
        return;
      }
      final selected = await showModalBottomSheet<ApiUserSearchResult>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text('Kết quả tìm kiếm',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              for (final user in results)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        user.avatar == null ? null : NetworkImage(user.avatar!),
                    child: user.avatar == null
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  title: Text(user.fullName),
                  subtitle: user.username == null ||
                          user.username!.trim().isEmpty
                      ? null
                      : Text(
                          '@${user.username!.replaceFirst(RegExp(r'^@'), '')}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, user),
                ),
            ],
          ),
        ),
      );
      if (selected != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PersonalProfilePage(
            fullName: selected.fullName,
            username: selected.username ?? '',
            userId: selected.id,
            avatarUrl: selected.avatar,
            isOwner: false,
            // The search response has no privacy flag. Don't infer local prefs
            // from this device as the privacy state of a remote account.
            profileIsPrivate: false,
          ),
        ));
      }
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }
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

class _PostDraft {
  const _PostDraft(
      {required this.title, required this.location, required this.content});
  final String title;
  final String location;
  final String content;
}

class _CreatePostPage extends StatefulWidget {
  const _CreatePostPage();

  @override
  State<_CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<_CreatePostPage> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _publish() {
    final caption = _captionController.text.trim();
    final location = _locationController.text.trim();
    if (caption.isEmpty || location.isEmpty) return;
    final firstLine = caption.split(RegExp(r'[\n.!?]')).first.trim();
    final title = (firstLine.isEmpty ? caption : firstLine);
    Navigator.of(context).pop(
      _PostDraft(
        title: title.length > 200 ? title.substring(0, 200) : title,
        content: caption,
        location: location,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = _captionController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty;
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
                  TextField(
                    controller: _captionController,
                    autofocus: true,
                    minLines: 6,
                    maxLines: 10,
                    maxLength: 2000,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      hintText: 'Kể về chuyến đi hoặc trải nghiệm của bạn...',
                      hintStyle: TextStyle(
                        color: Color(0xFFB3BAC2),
                        height: 1.45,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_captionController.text.length}/2000',
                      style: const TextStyle(color: Color(0xFF9AA2AA)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'API hiện tại chưa hỗ trợ tải ảnh bài viết; bài đăng sẽ gồm nội dung và địa điểm.',
                    style: TextStyle(color: Color(0xFF7C8793), fontSize: 13),
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
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Địa điểm *',
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

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.name,
    required this.avatarPath,
    required this.avatarUrl,
    required this.canDelete,
    required this.onDelete,
  });

  final ApiPost post;
  final String name;
  final String? avatarPath;
  final String? avatarUrl;
  final bool canDelete;
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
                    foregroundImage: _profileAvatarImage(avatarPath, avatarUrl),
                    child: avatarPath == null && avatarUrl == null
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
                  if (canDelete)
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
              if (post.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (post.title.isNotEmpty)
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: _profileNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (post.title.isNotEmpty) const SizedBox(height: 6),
                Text(post.content, style: const TextStyle(height: 1.4)),
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
              if (post.rating > 0) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFB400), size: 18),
                  const SizedBox(width: 4),
                  Text('${post.rating}/5'),
                ]),
              ],
            ],
          ),
        ),
      );
}

ImageProvider<Object>? _profileAvatarImage(String? path, String? url) {
  if (path != null && path.isNotEmpty) return FileImage(File(path));
  if (url != null && url.isNotEmpty) return NetworkImage(url);
  return null;
}
