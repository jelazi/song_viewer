#ifndef RUNNER_MULTI_WINDOW_HELPER_H_
#define RUNNER_MULTI_WINDOW_HELPER_H_

#include <windows.h>

// Helper functions for multi-window support
void MoveWindowToSecondaryMonitor(HWND hwnd);
void EnterFullscreen(HWND hwnd);

#endif  // RUNNER_MULTI_WINDOW_HELPER_H_
