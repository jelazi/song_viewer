part of 'settings_bloc.dart';

class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class _SettingsInitial extends SettingsEvent {}

class ChangeSettingsValue extends SettingsEvent {
  final String typeValue;
  final dynamic value;
  const ChangeSettingsValue(this.typeValue, this.value);
  @override
  List<Object> get props => [typeValue, value];
}

class AddQrLink extends SettingsEvent {
  final String label;
  final String url;
  const AddQrLink(this.label, this.url);
  @override
  List<Object> get props => [label, url];
}

class UpdateQrLink extends SettingsEvent {
  final int index;
  final String label;
  final String url;
  const UpdateQrLink(this.index, this.label, this.url);
  @override
  List<Object> get props => [index, label, url];
}

class RemoveQrLink extends SettingsEvent {
  final int index;
  const RemoveQrLink(this.index);
  @override
  List<Object> get props => [index];
}

class SyncQrLinksFromFirebase extends SettingsEvent {
  final List<QrLink> links;
  const SyncQrLinksFromFirebase(this.links);
  @override
  List<Object> get props => [links];
}
