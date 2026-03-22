"""
Simulator control module
"""
import subprocess
import time
from pathlib import Path
import json

class SimulatorController:
    def __init__(self, simulator_id, app_bundle):
        self.simulator_id = simulator_id
        self.app_bundle = app_bundle
        
    def get_simulator_id(self):
        """Get the actual UUID of the simulator by name"""
        try:
            result = subprocess.run(
                "xcrun simctl list devices --json",
                shell=True, capture_output=True, text=True
            )
            devices = json.loads(result.stdout)
            
            for runtime, device_list in devices['devices'].items():
                for device in device_list:
                    if device['name'] == self.simulator_id:
                        return device['udid']
            
            # If not found by name, assume it's already a UUID
            return self.simulator_id
        except:
            return self.simulator_id
    
    def boot(self):
        """Boot the simulator"""
        sim_id = self.get_simulator_id()
        subprocess.run(f"xcrun simctl boot {sim_id}", shell=True, capture_output=True)
        time.sleep(2)
        
    def launch_app(self):
        """Launch the app"""
        sim_id = self.get_simulator_id()
        subprocess.run(f"xcrun simctl terminate {sim_id} {self.app_bundle}", 
                      shell=True, capture_output=True)
        time.sleep(1)
        result = subprocess.run(f"xcrun simctl launch {sim_id} {self.app_bundle}", 
                               shell=True, capture_output=True, text=True)
        time.sleep(2)
        return "launched" in result.stdout.lower() or result.returncode == 0
        
    def terminate_app(self):
        """Terminate the app"""
        sim_id = self.get_simulator_id()
        subprocess.run(f"xcrun simctl terminate {sim_id} {self.app_bundle}", 
                      shell=True, capture_output=True)
        
    def screenshot(self, filename):
        """Take a screenshot"""
        sim_id = self.get_simulator_id()
        Path(filename).parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            f"xcrun simctl io {sim_id} screenshot {filename}",
            shell=True, capture_output=True, text=True
        )
        return Path(filename).exists()
    
    def click(self, x, y):
        """Simulate a click at position using AppleScript"""
        script = f'''
        tell application "Simulator" to activate
        delay 0.3
        tell application "System Events"
            click at {{{x}, {y}}}
        end tell
        '''
        subprocess.run(['osascript', '-e', script], capture_output=True)
        time.sleep(0.5)
        
    def open_simulator_app(self):
        """Open the Simulator app"""
        subprocess.run("open -a Simulator", shell=True)
        time.sleep(2)