import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../providers/highlight_provider.dart';
import '../models/highlight_model.dart';

class HighlightsSection extends StatefulWidget {
  final bool isAdmin;
  final VoidCallback onUpload;

  const HighlightsSection({
    super.key,
    required this.isAdmin,
    required this.onUpload,
  });

  @override
  State<HighlightsSection> createState() => _HighlightsSectionState();
}

class _HighlightsSectionState extends State<HighlightsSection> {
  String _selectedCategory = 'Game Highlights';
  final List<String> _categories = [
    'Game Highlights',
    'Tournament Videos',
    'Interview Videos',
  ];

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HighlightProvider>(context, listen: false).fetchHighlights();
    });
  }

  Future<void> _initializePlayer(String videoUrl, {bool isAsset = false}) async {
    if (_currentVideoUrl == videoUrl) return;

    _disposeControllers();
    
    try {
      if (isAsset) {
        _videoPlayerController = VideoPlayerController.asset(videoUrl);
      } else {
         // Assuming backend returns relative path, append base url or handling if full url
         // For Django media, it's usually relative or full depending on settings. Assuming full or relative needs handling.
         // Let's assume full URL from backend serializer if configured, or keys from provider. 
         // Actually, serializer FileField returns full relative path usually or absolute if request passed.
         // To be safe, if it starts with http, use it, else prepend base url.
         // However, HighlightProvider base url is localhost. Android emulator needs 10.0.2.2.
         // For now let's try direct network load. Use the URL as is.
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      
      await _videoPlayerController!.initialize();
      _createChewieController();
      _currentVideoUrl = videoUrl;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      autoPlay: true,
      looping: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF3A8FB7),
        handleColor: Colors.white,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white54,
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF3A8FB7))),
      ),
    );
  }

  void _disposeControllers() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _showAdminOptions(BuildContext context, HighlightModel video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Edit Details', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(video);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Video', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(video);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showEditDialog(HighlightModel video) {
    final titleController = TextEditingController(text: video.title);
    String selectedCategory = video.category;
    // Capture provider before dialog to avoid context context issues
    final provider = Provider.of<HighlightProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Highlight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categories.contains(selectedCategory) ? selectedCategory : _categories[0],
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => selectedCategory = val!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await provider.updateHighlight(
                id: video.id,
                title: titleController.text,
                category: selectedCategory,
              );
              if (mounted) { 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(HighlightModel video) {
    // Capture provider before dialog
    final provider = Provider.of<HighlightProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Video?'),
        content: Text('Are you sure you want to delete "${video.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // If deleted video is playing, stop it
              if (_currentVideoUrl == video.videoFile) {
                  _disposeControllers();
                  setState(() { _currentVideoUrl = null; });
              }
              
              await provider.deleteHighlight(video.id);
              
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted!')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HighlightProvider>(
      builder: (context, provider, child) {
        final categoryHighlights = provider.highlights
            .where((h) => h.category == _selectedCategory)
            .toList();

        // If no videos in category, maybe show default asset video as a placeholder 'Featured' 
        // OR just show empty state.
        // The user previously had 'assets/video/highlight.mp4'. Let's keep one "Default" entry if list is empty,
        // so the UI isn't broken.
        final bool hasVideos = categoryHighlights.isNotEmpty;
        
        // Auto-play first video if not playing anything and we have videos
        if (hasVideos && _currentVideoUrl == null) {
             // Defer to next frame
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 final url = categoryHighlights.first.videoFile ?? categoryHighlights.first.videoUrl;
                 if (url != null) _initializePlayer(url); 
             });
        } else if (!hasVideos && _currentVideoUrl == null) {
            // Play default asset
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 _initializePlayer('assets/video/highlight.mp4', isAsset: true);
             });
        }


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Highlights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontFamily: 'Serif',
                    ),
                  ),
                  if (widget.isAdmin)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A8FB7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFF3A8FB7)),
                      ),
                      tooltip: 'Upload Highlight',
                      onPressed: widget.onUpload,
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() {
                        _selectedCategory = category;
                        _currentVideoUrl = null; // Reset player on category switch
                        _disposeControllers();
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3A8FB7) : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3A8FB7).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _chewieController != null &&
                      _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator(color: Color(0xFF3A8FB7))),
            ),

            const SizedBox(height: 16),

            if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
            else if (!hasVideos)
                 Padding(
                   padding: const EdgeInsets.all(24.0),
                   child: Text(
                     "No videos in this category yet.", 
                     style: TextStyle(color: Colors.white60)
                   ),
                 )
            else
              SizedBox(
                height: 140,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryHighlights.length,
                  itemBuilder: (context, index) {
                    final video = categoryHighlights[index];
                    final videoSource = video.videoFile ?? video.videoUrl;
                    final isPlaying = _currentVideoUrl == videoSource;
                    
                    return GestureDetector(
                      onTap: () {
                          if (videoSource != null) {
                              _initializePlayer(videoSource);
                          }
                      },
                      onLongPress: widget.isAdmin ? () => _showAdminOptions(context, video) : null,
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white10,
                          image: video.thumbnail != null 
                             ? DecorationImage(
                                  image: NetworkImage(video.thumbnail!),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.4), 
                                    BlendMode.darken
                                  ),
                               )
                             : null, // Fallback to color if no thumb
                          border: isPlaying 
                            ? Border.all(color: const Color(0xFF3A8FB7), width: 2)
                            : null,
                        ),
                        child: Stack(
                          children: [
                            if (video.thumbnail == null)
                               const Center(child: Icon(Icons.movie, color: Colors.white24, size: 50)),
                            
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Text(
                                video.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.isAdmin)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                   onTap: () => _showAdminOptions(context, video),
                                   child: Container(
                                     decoration: BoxDecoration(
                                       color: Colors.black54,
                                       shape: BoxShape.circle,
                                     ),
                                     padding: const EdgeInsets.all(4),
                                     child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                                   ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
