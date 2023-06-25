from flask import Flask, render_template, request, redirect
import subprocess

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/wifi', methods=['GET', 'POST'])
def wifi():
    if request.method == 'POST':
        ssid = request.form['ssid']
        password = request.form['password']
        subprocess.run(['sudo', 'wpa_cli', '-i', 'wlan0', 'scan'])
        subprocess.run(['sudo', 'wpa_cli', '-i', 'wlan0', 'add_network'])
        subprocess.run(['sudo', 'wpa_cli', '-i', 'wlan0', 'set_network', '0', 'ssid', f'"{ssid}"'])
        subprocess.run(['sudo', 'wpa_cli', '-i', 'wlan0', 'set_network', '0', 'psk', f'"{password}"'])
        subprocess.run(['sudo', 'wpa_cli', '-i', 'wlan0', 'enable_network', '0'])
        subprocess.run(['sudo', 'wpa_cli', '-i', 'wlan0', 'save_config'])
        return redirect('/')
    else:
        return render_template('wifi.html')

@app.route('/bluetooth', methods=['GET', 'POST'])
def bluetooth():
    if request.method == 'POST':
        name = request.form['name']
        pin = request.form['pin']

        subprocess.run(['sudo', 'hciconfig', 'hci0', 'name', name])
        subprocess.run(['sudo', 'sh', '-c', f"echo {pin} > /etc/bluetooth/pin.conf"])

        # Update the Bluetooth agent configuration
        subprocess.run(['sudo', 'systemctl', 'stop', 'bluetooth-agent'])
        subprocess.run(['sudo', 'sed', '-i', f's/--name=.*/--name="{name}"/g', '/etc/systemd/system/bluetooth-agent.service'])
        subprocess.run(['sudo', 'sed', '-i', f's/--passkey=.*/--passkey="{pin}"/g', '/etc/systemd/system/bluetooth-agent.service'])
        subprocess.run(['sudo', 'systemctl', 'start', 'bluetooth-agent'])

        return redirect('/')
    else:
        return render_template('bluetooth.html')

@app.route('/status')
def status():
    # Get device information
    device_info = {}
    device_info['name'] = subprocess.check_output(['hostname']).decode().strip()
    device_info['bluetooth_connected'] = subprocess.check_output(['hcitool', 'con']).decode().strip() != ''
    device_info['wifi_connected'] = subprocess.check_output(['iwgetid', '-r']).decode().strip() != ''
    # Add more information as needed

    return jsonify(device_info)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
