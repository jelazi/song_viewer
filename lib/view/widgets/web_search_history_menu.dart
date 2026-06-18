import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../blocs/export_blocs.dart';
import '../../services/constants.dart';

/// A history dropdown for the web search fields.
///
/// Shows the persisted search queries for the current server and, separately,
/// the combined history across all servers. Selecting an item calls
/// [onSelected]; a "clear" action wipes the current server's history.
class WebSearchHistoryMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const WebSearchHistoryMenu({super.key, required this.onSelected});

  // Sentinels kept out of the way of any realistic query text.
  static const String _pickPrefix = 'pick';
  static const String _clearValue = 'clear';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebBloc, WebState>(
      buildWhen: (p, c) => p.searchHistory != c.searchHistory || p.allSearchHistory != c.allSearchHistory,
      builder: (context, state) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.history, color: AppColor.grey1Color, size: 20),
          tooltip: 'searchHistory'.tr(),
          onSelected: (value) {
            if (value == _clearValue) {
              context.read<WebBloc>().add(const ClearWebSearchHistory());
              return;
            }
            if (value.startsWith(_pickPrefix)) {
              onSelected(value.substring(_pickPrefix.length));
            }
          },
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[];
            final thisServer = state.searchHistory;
            final allServers = state.allSearchHistory;

            if (thisServer.isEmpty && allServers.isEmpty) {
              items.add(PopupMenuItem<String>(
                enabled: false,
                child: Text('noSearchHistory'.tr(), style: const TextStyle(color: AppColor.grey2Color)),
              ));
              return items;
            }

            if (thisServer.isNotEmpty) {
              items.add(_header('searchHistoryThisServer'.tr()));
              for (final q in thisServer.take(10)) {
                items.add(_queryItem(q));
              }
            }

            if (allServers.isNotEmpty) {
              if (thisServer.isNotEmpty) items.add(const PopupMenuDivider());
              items.add(_header('searchHistoryAllServers'.tr()));
              for (final q in allServers.take(10)) {
                items.add(_queryItem(q));
              }
            }

            items.add(const PopupMenuDivider());
            items.add(PopupMenuItem<String>(
              value: _clearValue,
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, size: 18, color: AppColor.alertErrorColor),
                  const SizedBox(width: 8),
                  Text('clearHistory'.tr(), style: const TextStyle(color: AppColor.alertErrorColor)),
                ],
              ),
            ));
            return items;
          },
        );
      },
    );
  }

  PopupMenuEntry<String> _header(String label) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 28,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColor.grey2Color, letterSpacing: 0.8),
      ),
    );
  }

  PopupMenuEntry<String> _queryItem(String query) {
    return PopupMenuItem<String>(
      value: '$_pickPrefix$query',
      height: 38,
      child: Row(
        children: [
          const Icon(Icons.north_west, size: 16, color: AppColor.grey1Color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: AppColor.grey1Color)),
          ),
        ],
      ),
    );
  }
}
