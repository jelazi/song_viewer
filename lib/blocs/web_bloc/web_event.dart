part of 'web_bloc.dart';

class WebEvent extends Equatable {
  const WebEvent();

  @override
  List<Object> get props => [];
}

class ChangeCurrentWebSong extends WebEvent {
  final WebSong? song;
  const ChangeCurrentWebSong({required this.song});
}

class ChangeCurrentInterpret extends WebEvent {
  final WebInterpret interpret;
  const ChangeCurrentInterpret({required this.interpret});
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
