#!/usr/bin/env python3
import json
import subprocess
import time
import sys
import psutil
import threading
from collections import namedtuple

# Use namedtuple for faster attribute access
NetworkStats = namedtuple('NetworkStats', ['bytes_recv', 'bytes_sent'])

class NetworkMonitor:
    def __init__(self):
        self.last_io = None
        self.last_time = 0
        self.saved_networks_cache = set()
        self.saved_networks_cache_time = 0
        self.last_wifi_scan = ""
        self.last_networks = []
        
    def format_speed(self, bps):
        """Optimized speed formatting with early returns"""
        if bps < 1024:
            return f"{bps:.0f} B/s"
        bps_kb = bps / 1024
        if bps_kb < 1024:
            return f"{bps_kb:.1f} KB/s"
        bps_mb = bps_kb / 1024
        if bps_mb < 1024:
            return f"{bps_mb:.1f} MB/s"
        return f"{bps_mb / 1024:.2f} GB/s"
    
    def get_active_interface(self):
        """Cached interface lookup - only check when needed"""
        if not hasattr(self, '_cached_interface') or time.time() - getattr(self, '_iface_cache_time', 0) > 5:
            try:
                stats = psutil.net_if_stats()
                for iface, stat in stats.items():
                    if stat.isup and not iface.startswith('lo'):
                        self._cached_interface = iface
                        self._iface_cache_time = time.time()
                        return iface
            except:
                pass
            self._cached_interface = None
            self._iface_cache_time = time.time()
        return self._cached_interface
    
    def get_network_speed(self):
        """Optimized network speed calculation"""
        try:
            iface = self.get_active_interface()
            if not iface:
                return 0, 0
            
            io_all = psutil.net_io_counters(pernic=True)
            if iface not in io_all:
                return 0, 0
            
            io = io_all[iface]
            now = time.time()
            
            if self.last_io and self.last_time > 0:
                dt = now - self.last_time
                if dt > 0:
                    # Use namedtuple for faster access
                    rx_diff = io.bytes_recv - self.last_io.bytes_recv
                    tx_diff = io.bytes_sent - self.last_io.bytes_sent
                    
                    if rx_diff >= 0 and tx_diff >= 0:
                        download = rx_diff / dt
                        upload = tx_diff / dt
                        self.last_io = NetworkStats(io.bytes_recv, io.bytes_sent)
                        self.last_time = now
                        return download, upload
            
            self.last_io = NetworkStats(io.bytes_recv, io.bytes_sent)
            self.last_time = now
            return 0, 0
        except:
            return 0, 0
    
    def run_nmcli(self, args):
        """Optimized nmcli execution with shorter timeout"""
        try:
            return subprocess.check_output(
                ["nmcli"] + args,
                stderr=subprocess.DEVNULL,
                timeout=1  # Reduced from 2
            ).decode().strip()
        except:
            return ""
    
    def get_saved_networks(self):
        """Cached saved networks - refresh every 10 seconds"""
        now = time.time()
        if now - self.saved_networks_cache_time < 10:
            return self.saved_networks_cache
        
        try:
            output = self.run_nmcli(["-t", "-f", "NAME,TYPE", "connection", "show"])
            saved = set()
            for line in output.split('\n'):
                if not line:
                    continue
                # Faster split with maxsplit
                parts = line.split(':', 1)
                if len(parts) == 2 and '802-11-wireless' in parts[1]:
                    saved.add(parts[0])
            
            self.saved_networks_cache = saved
            self.saved_networks_cache_time = now
            return saved
        except:
            return self.saved_networks_cache
    
    def get_wifi_icon(self, strength, enabled, status, ethernet):
        """Pre-computed icon selection"""
        if ethernet:
            return "lan"
        if not enabled:
            return "signal_wifi_off"
        if status == "connecting":
            return "signal_wifi_statusbar_not_connected"
        if status != "connected":
            return "wifi_find"
        
        # Optimized array lookup
        icons = ("signal_wifi_0_bar", "network_wifi_1_bar", "network_wifi_2_bar", 
                 "network_wifi_3_bar", "network_wifi", "signal_wifi_4_bar")
        return icons[min(5, max(0, strength // 17))]
    
    def parse_networks(self, nets_out):
        """Optimized network parsing with caching"""
        # Skip parsing if output hasn't changed
        if nets_out == self.last_wifi_scan:
            return self.last_networks
        
        self.last_wifi_scan = nets_out
        saved_networks = self.get_saved_networks()
        
        networks = []
        seen = set()
        
        for line in nets_out.split('\n'):
            if not line:
                continue
            
            # Optimize colon handling
            parts = line.replace('\\:', '\x00').split(':')
            if len(parts) < 3:
                continue
            
            ssid = parts[2].replace('\x00', ':')
            if not ssid or ssid in seen:
                continue
            
            seen.add(ssid)
            
            try:
                strength = int(parts[1]) if parts[1] else 0
            except:
                strength = 0
            
            has_security = len(parts) > 3 and parts[3]
            
            networks.append({
                "active": parts[0] == "yes",
                "strength": strength,
                "strength_text": f"{strength}%",
                "ssid": ssid,
                "security": parts[3] if len(parts) > 3 else "",
                "security_text": "Secured" if has_security else "Open",
                "saved": ssid in saved_networks
            })
        
        self.last_networks = networks
        return networks
    
    def get_status(self):
        """Optimized status collection"""
        try:
            # Get interface info (cached)
            iface = self.get_active_interface() or ""
            ethernet = any(x in iface for x in ('eth', 'enp', 'eno'))
            wifi = any(x in iface for x in ('wlan', 'wlp'))
            
            # Get WiFi state
            wifi_enabled = self.run_nmcli(["radio", "wifi"]) == "enabled"
            
            # Simplified status check
            wifi_status = "disconnected"
            signal = 0
            
            if wifi:
                # Batch status and signal query in one call for efficiency
                combined = self.run_nmcli(["-t", "-f", "TYPE,STATE", "d", "status"])
                if "wifi:connected" in combined:
                    wifi_status = "connected"
                    # Only get signal if connected
                    sig_out = self.run_nmcli(["-f", "IN-USE,SIGNAL", "device", "wifi"])
                    for line in sig_out.split('\n'):
                        if line.lstrip().startswith('*'):
                            parts = line.split()
                            if len(parts) >= 2:
                                try:
                                    signal = int(parts[1])
                                except:
                                    pass
                                break
                elif "wifi:connecting" in combined:
                    wifi_status = "connecting"
            
            # Get active connection name
            network_name = self.run_nmcli(["-t", "-f", "NAME", "c", "show", "--active"]).split('\n')[0] if wifi or ethernet else ""
            
            # Get speeds (uses psutil - very fast)
            download, upload = self.get_network_speed()
            
            # Parse networks with caching
            networks = []
            if wifi_enabled:
                nets_out = self.run_nmcli(["-g", "ACTIVE,SIGNAL,SSID,SECURITY", "d", "w"])
                networks = self.parse_networks(nets_out)
            else:
                self.last_wifi_scan = ""
                self.last_networks = []
            
            return {
                "wifi_enabled": wifi_enabled,
                "ethernet": ethernet,
                "wifi": wifi,
                "wifi_status": wifi_status,
                "network_name": network_name,
                "signal_strength": signal,
                "signal_strength_text": f"{signal}%",
                "material_icon": self.get_wifi_icon(signal, wifi_enabled, wifi_status, ethernet),
                "wifi_networks": networks,
                "download_speed": download,
                "upload_speed": upload,
                "download_speed_text": self.format_speed(download),
                "upload_speed_text": self.format_speed(upload)
            }
        except Exception as e:
            return {
                "wifi_enabled": False,
                "ethernet": False,
                "wifi": False,
                "wifi_status": "unknown",
                "network_name": "",
                "signal_strength": 0,
                "signal_strength_text": "0%",
                "material_icon": "signal_wifi_bad",
                "wifi_networks": [],
                "download_speed": 0,
                "upload_speed": 0,
                "download_speed_text": "0 B/s",
                "upload_speed_text": "0 B/s",
                "error": str(e)
            }
    
    def handle_command(self, cmd_line):
        """Command handler with cache invalidation"""
        try:
            cmd = json.loads(cmd_line)
            action = cmd.get("action")
            
            if action == "enable_wifi":
                mode = "on" if cmd.get("enabled", True) else "off"
                self.run_nmcli(["radio", "wifi", mode])
                self._cached_interface = None  # Invalidate cache
            
            elif action == "toggle_wifi":
                current = self.run_nmcli(["radio", "wifi"]) == "enabled"
                self.run_nmcli(["radio", "wifi", "off" if current else "on"])
                self._cached_interface = None
            
            elif action == "rescan_wifi":
                self.run_nmcli(["dev", "wifi", "list", "--rescan", "yes"])
                self.last_wifi_scan = ""  # Invalidate network cache
            
            elif action == "connect":
                ssid = cmd.get("ssid", "")
                password = cmd.get("password", "")
                if ssid:
                    args = ["dev", "wifi", "connect", ssid]
                    if password:
                        args.extend(["password", password])
                    self.run_nmcli(args)
                    self.saved_networks_cache_time = 0  # Invalidate saved networks cache
            
            elif action == "disconnect":
                ssid = cmd.get("ssid", "")
                if ssid:
                    self.run_nmcli(["connection", "down", ssid])
            
            elif action == "forget":
                ssid = cmd.get("ssid", "")
                if ssid:
                    self.run_nmcli(["connection", "delete", ssid])
                    self.saved_networks_cache_time = 0
            
        except Exception as e:
            print(json.dumps({"error": f"Command error: {str(e)}"}), file=sys.stderr, flush=True)

def stdin_reader(monitor):
    """Optimized stdin reader"""
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            if line.strip():  # Skip empty lines
                monitor.handle_command(line.strip())
        except:
            break

def main():
    sys.stdout.reconfigure(line_buffering=True)
    sys.stderr.reconfigure(line_buffering=True)
    
    monitor = NetworkMonitor()
    
    # Start stdin reader
    thread = threading.Thread(target=stdin_reader, args=(monitor,), daemon=True)
    thread.start()
    
    print(json.dumps({"status": "started"}), flush=True)
    
    while True:
        try:
            status = monitor.get_status()
            print(json.dumps(status), flush=True)
            time.sleep(1)
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(json.dumps({"error": str(e)}), flush=True)
            time.sleep(1)

if __name__ == "__main__":
    main()
