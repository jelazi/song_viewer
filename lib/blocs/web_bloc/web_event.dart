part of 'web_bloc.dart';

class WebEvent extends Equatable {
  const WebEvent();

  @override
  List<Object> get props => [];
}

class _Init extends WebEvent {
  const _Init();
}

class ChangeCurrentWebSong extends WebEvent {
  final WebSong? song;
  final String typeSearching;
  const ChangeCurrentWebSong({required this.song, required this.typeSearching});
}

class ChangeCurrentInterpret extends WebEvent {
  final WebInterpret? interpret;

  const ChangeCurrentInterpret({required this.interpret});
}

class FilterInterprets extends WebEvent {
  final String filter;
  const FilterInterprets({required this.filter});
}

class FilterSongs extends WebEvent {
  final String filter;
  const FilterSongs({required this.filter});
}

class LoadSongs extends WebEvent {
  const LoadSongs();
}

class LoadInterprets extends WebEvent {
  const LoadInterprets();
}

class ChangeSearchWeb extends WebEvent {
  final int searchWeb;
  const ChangeSearchWeb({required this.searchWeb});
}

class ChangeSearchType extends WebEvent {
  final int searchType;
  const ChangeSearchType({required this.searchType});
}

class TestWebEvent extends WebEvent {
  const TestWebEvent();
}

/// Zoom the previewed web song in or out.
///
/// Writes the same settings keys as the library preview, so both views keep a
/// single font size instead of drifting apart.
class ChangeWebFontSize extends WebEvent {
  final bool isIncrease;
  const ChangeWebFontSize({required this.isIncrease});

  @override
  List<Object> get props => [isIncrease];
}

/// Switch the previewed web song between the notation the site published and
/// the Czech one (`B` → `H`, `Bb` → `B`, flats to sharps).
class ToggleChordNotation extends WebEvent {
  const ToggleChordNotation();
}

/// Transpose the chords of the previewed web song.
///
/// The increment lives in the state only: a web song has no library id yet, so
/// there is nothing to persist it against until the song is saved.
class TransposeWebChord extends WebEvent {
  final int increment;
  const TransposeWebChord({required this.increment});

  @override
  List<Object> get props => [increment];
}

/// Persist a search query into the history for the current server.
class AddWebSearchHistory extends WebEvent {
  final String query;
  const AddWebSearchHistory({required this.query});

  @override
  List<Object> get props => [query];
}

/// Clear the search history for the current server (and rebuild the combined list).
class ClearWebSearchHistory extends WebEvent {
  const ClearWebSearchHistory();
}
