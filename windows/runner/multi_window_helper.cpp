#include "multi_window_helper.h"
#include <vector>

// Structure to hold monitor enumeration data
struct MonitorEnumData {
    std::vector<HMONITOR> monitors;
    HMONITOR primaryMonitor;
};

// Callback for EnumDisplayMonitors
BOOL CALLBACK MonitorEnumProc(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData) {
    MonitorEnumData* data = reinterpret_cast<MonitorEnumData*>(dwData);
    data->monitors.push_back(hMonitor);
    return TRUE;
}

void MoveWindowToSecondaryMonitor(HWND hwnd) {
    // Get primary monitor
    POINT pt = {0, 0};
    HMONITOR primaryMonitor = MonitorFromPoint(pt, MONITOR_DEFAULTTOPRIMARY);
    
    // Enumerate all monitors
    MonitorEnumData enumData;
    enumData.primaryMonitor = primaryMonitor;
    EnumDisplayMonitors(NULL, NULL, MonitorEnumProc, reinterpret_cast<LPARAM>(&enumData));
    
    // Find secondary monitor (first one that's not primary)
    HMONITOR targetMonitor = primaryMonitor;
    for (HMONITOR monitor : enumData.monitors) {
        if (monitor != primaryMonitor) {
            targetMonitor = monitor;
            break;
        }
    }
    
    // Get monitor info
    MONITORINFO monitorInfo;
    monitorInfo.cbSize = sizeof(MONITORINFO);
    GetMonitorInfo(targetMonitor, &monitorInfo);
    
    // Calculate window position (90% of monitor size, centered)
    RECT workArea = monitorInfo.rcWork;
    int width = static_cast<int>((workArea.right - workArea.left) * 0.9);
    int height = static_cast<int>((workArea.bottom - workArea.top) * 0.9);
    int x = workArea.left + (workArea.right - workArea.left - width) / 2;
    int y = workArea.top + (workArea.bottom - workArea.top - height) / 2;
    
    // Move and resize window
    SetWindowPos(hwnd, HWND_TOP, x, y, width, height, SWP_SHOWWINDOW);
}

void EnterFullscreen(HWND hwnd) {
    // Get current window style
    LONG style = GetWindowLong(hwnd, GWL_STYLE);
    
    // Remove window decorations for fullscreen
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE | WS_SYSMENU);
    SetWindowLong(hwnd, GWL_STYLE, style);
    
    // Get monitor the window is currently on
    HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    
    // Get monitor info
    MONITORINFO monitorInfo;
    monitorInfo.cbSize = sizeof(MONITORINFO);
    GetMonitorInfo(monitor, &monitorInfo);
    
    // Set window to cover entire monitor
    SetWindowPos(hwnd, HWND_TOP,
                 monitorInfo.rcMonitor.left,
                 monitorInfo.rcMonitor.top,
                 monitorInfo.rcMonitor.right - monitorInfo.rcMonitor.left,
                 monitorInfo.rcMonitor.bottom - monitorInfo.rcMonitor.top,
                 SWP_FRAMECHANGED | SWP_SHOWWINDOW);
}
