import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/backup_service.dart';

class BackupRestoreBody extends StatefulWidget {
  const BackupRestoreBody({super.key});

  @override
  State<BackupRestoreBody> createState() => _BackupRestoreBodyState();
}

class _BackupRestoreBodyState extends State<BackupRestoreBody> {
  String _status = '';
  bool _isRunning = false;
  BackupResult? _lastResult;

  // Preview data for restore
  String? _selectedRestoreDir;
  BackupResult? _restorePreview;

  Future<void> _doExport() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Vyberte složku pro zálohu',
    );
    if (dir == null) return;

    // Create a timestamped subfolder
    final now = DateTime.now();
    final folderName =
        'SongsViewer_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final backupPath = '$dir${Platform.pathSeparator}$folderName';

    if (!mounted) return;
    final service = _buildService();

    setState(() {
      _isRunning = true;
      _status = 'Zahajuji zálohu...';
      _lastResult = null;
    });

    final result = await service.exportBackup(
      backupPath,
      onProgress: (msg) {
        if (mounted) setState(() => _status = msg);
      },
    );

    if (mounted) {
      setState(() {
        _isRunning = false;
        _lastResult = result;
        _status = result.message;
      });
    }
  }

  Future<void> _selectRestoreDir() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Vyberte složku se zálohou (obsahující backup.json)',
    );
    if (dir == null) return;

    if (!mounted) return;
    final service = _buildService();

    setState(() {
      _isRunning = true;
      _status = 'Kontroluji zálohu...';
      _restorePreview = null;
      _selectedRestoreDir = dir;
    });

    final preview = await service.previewBackup(dir);

    if (mounted) {
      setState(() {
        _isRunning = false;
        _restorePreview = preview;
        _status = preview.message;
      });
    }
  }

  Future<void> _doRestore() async {
    if (_selectedRestoreDir == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrdit obnovu'),
        content: const Text(
          'Tato akce přepíše všechna stávající data (písně, playlisty, skupiny, uživatele, akordy, nastavení).\n\n'
          'Jste si jisti?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obnovit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final service = _buildService();

    setState(() {
      _isRunning = true;
      _status = 'Zahajuji obnovu...';
      _lastResult = null;
    });

    final result = await service.importBackup(
      _selectedRestoreDir!,
      onProgress: (msg) {
        if (mounted) setState(() => _status = msg);
      },
    );

    if (mounted) {
      setState(() {
        _isRunning = false;
        _lastResult = result;
        _status = result.message;
        _restorePreview = null;
        _selectedRestoreDir = null;
      });
    }
  }

  BackupService _buildService() {
    final homePageBloc = context.read<HomePageBloc>();
    final playlistsBloc = context.read<PlaylistsBloc>();
    final usersBloc = context.read<UsersBloc>();
    return BackupService(
      songsRepository: homePageBloc.songsRepository,
      playlistRepository: playlistsBloc.playlistRepository,
      usersRepository: usersBloc.usersRepository,
      settingsRepository: homePageBloc.settingsRepository,
      pocketBaseProvider: homePageBloc.settingsRepository.pocketBaseProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Záloha a obnova',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Zálohuje vše: písně, playlisty, skupiny, uživatele, akordové diagramy, nastavení a přiložené soubory (noty).',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Divider(),

          // --- EXPORT ---
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.upload_file, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Vytvořit zálohu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _doExport,
                icon: const Icon(Icons.save),
                label: const Text('Exportovat'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Vyberte složku, kam se uloží záloha. Vytvoří se podsložka s datem a časem.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // --- IMPORT ---
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.download, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Obnovit ze zálohy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _isRunning ? null : _selectRestoreDir,
                icon: const Icon(Icons.folder_open),
                label: const Text('Vybrat složku'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Vyberte složku zálohy (obsahující backup.json a podsložku files).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          // Restore preview
          if (_restorePreview != null) ...[
            const SizedBox(height: 16),
            _buildPreviewCard(),
          ],

          // --- STATUS ---
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          if (_isRunning) ...[
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(_status)),
              ],
            ),
          ] else if (_lastResult != null) ...[
            _buildResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final preview = _restorePreview!;
    if (!preview.success) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(preview.message, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(preview.message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _countsTable(preview.counts),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _doRestore,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              icon: const Icon(Icons.restore, color: Colors.white),
              label: const Text('Obnovit tuto zálohu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _lastResult!;
    final color = result.success ? Colors.green : Colors.red;
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  result.message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            if (result.counts.isNotEmpty) ...[
              const SizedBox(height: 8),
              _countsTable(result.counts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _countsTable(Map<String, int> counts) {
    const labels = {
      'songs': 'Písně',
      'playlists': 'Playlisty',
      'groups': 'Skupiny',
      'users': 'Uživatelé',
      'chordDiagrams': 'Akordové diagramy',
      'files': 'Soubory (noty/obrázky)',
    };

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: counts.entries.map((e) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Text(labels[e.key] ?? e.key, style: const TextStyle(color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }).toList(),
    );
  }
}
