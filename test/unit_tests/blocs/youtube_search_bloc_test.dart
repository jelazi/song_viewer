import 'package:flutter_test/flutter_test.dart';
import 'package:song_viewer/blocs/youtube_search_bloc/youtube_search_bloc.dart';
import 'package:song_viewer/model/song/song.dart';
import 'package:song_viewer/model/youtube_video.dart';
import 'package:song_viewer/repositories/settings_repository.dart';
import 'package:song_viewer/repositories/songs_repository.dart';
import 'package:song_viewer/services/ai_search_service.dart';

class _FakeAiSearchService extends AiSearchService {
  List<YoutubeSearchResult> results = [];
  bool fail = false;
  String? lastQuery;

  @override
  Future<List<YoutubeSearchResult>> searchYoutube({
    required String apiKey,
    required String query,
    int maxResults = 5,
    bool throwOnError = false,
  }) async {
    lastQuery = query;
    if (fail) throw Exception('quota exceeded');
    return results;
  }
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  String get youtubeApiKey => 'test-key';
}

class _FakeSongsRepository extends Fake implements SongsRepository {
  final updatedSongs = <Song>[];
  int notifications = 0;

  @override
  Future<void> updateSong(Song song) async => updatedSongs.add(song);

  @override
  void notifySongsChanged() => notifications++;
}

YoutubeSearchResult _result(String videoId, {String title = 'Title'}) {
  return YoutubeSearchResult(title: title, videoId: videoId, thumbnailUrl: '', channelTitle: 'Channel');
}

void main() {
  late _FakeAiSearchService searchService;
  late _FakeSongsRepository songsRepository;
  late YoutubeSearchBloc bloc;

  setUp(() {
    searchService = _FakeAiSearchService();
    songsRepository = _FakeSongsRepository();
    bloc = YoutubeSearchBloc(
      aiSearchService: searchService,
      settingsRepository: _FakeSettingsRepository(),
      songsRepository: songsRepository,
    );
  });

  tearDown(() => bloc.close());

  group('SearchYoutube', () {
    test('emits loading then results with unescaped titles', () async {
      searchService.results = [_result('abcdefghijk', title: 'Rock &amp; Roll &#39;n&#39; Praise')];

      bloc.add(const SearchYoutube(query: '  Ať požehnán je Bůh  '));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<YoutubeSearchState>().having((s) => s.status, 'status', YoutubeSearchStatus.loading),
          isA<YoutubeSearchState>()
              .having((s) => s.status, 'status', YoutubeSearchStatus.success)
              .having((s) => s.results.single.title, 'title', "Rock & Roll 'n' Praise"),
        ]),
      );
      expect(searchService.lastQuery, 'Ať požehnán je Bůh');
    });

    test('emits failure when the search throws', () async {
      searchService.fail = true;

      bloc.add(const SearchYoutube(query: 'song'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<YoutubeSearchState>().having((s) => s.status, 'status', YoutubeSearchStatus.loading),
          isA<YoutubeSearchState>().having((s) => s.status, 'status', YoutubeSearchStatus.failure),
        ]),
      );
    });

    test('ignores an empty query', () async {
      bloc.add(const SearchYoutube(query: '   '));
      await Future<void>.delayed(Duration.zero);

      expect(searchService.lastQuery, isNull);
      expect(bloc.state.status, YoutubeSearchStatus.initial);
    });
  });

  group('AddYoutubeVideoToSong', () {
    test('appends the video, saves the song and notifies listeners', () async {
      final song = Song(id: 's1', title: 'Song', lyrics: '', youtubeVideos: [YoutubeVideo(name: 'old', path: 'https://youtu.be/aaaaaaaaaaa')]);

      bloc.add(AddYoutubeVideoToSong(song: song, result: _result('bbbbbbbbbbb', title: 'New')));
      final state = await bloc.stream.first;

      final saved = songsRepository.updatedSongs.single;
      expect(saved.youtubeVideos!.map((video) => video.path), ['https://youtu.be/aaaaaaaaaaa', 'https://www.youtube.com/watch?v=bbbbbbbbbbb']);
      expect(saved.youtubeVideos!.last.name, 'New');
      expect(songsRepository.notifications, 1);
      expect(state.updatedSong, same(saved));
    });

    test('does nothing when the song already has the video', () async {
      final song = Song(id: 's1', title: 'Song', lyrics: '', youtubeVideos: [YoutubeVideo(name: 'old', path: 'https://www.youtube.com/watch?v=bbbbbbbbbbb')]);

      bloc.add(AddYoutubeVideoToSong(song: song, result: _result('bbbbbbbbbbb')));
      await Future<void>.delayed(Duration.zero);

      expect(songsRepository.updatedSongs, isEmpty);
      expect(songsRepository.notifications, 0);
    });
  });
}
